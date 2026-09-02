# frozen_string_literal: true

module ArelExtensions
  #
  # column_of
  #
  # Before the creation of these methods, getting the column name was done
  # uniquely through the code found in `column_of_via_arel_table`.
  #
  # This turned out to be unreliable, most notably when using adapters that do
  # not come with activerecord standard batteries. SQL Server is the most
  # notorious example.
  #
  # Currently, we're using a needlessly complicated way to address this issue.
  # Different versions of activerecord are behaving differently; the public APIs
  # do not seem to come with any guarantees, so we need to be sure that we're
  # coveing all these cases.

  def self.column_of_via_arel_table(table_name, column_name)
    Arel::Table.engine.connection.schema_cache.columns_hash(table_name)[column_name]
  rescue NoMethodError
    nil
  rescue StandardError => e
    warn("Warning: Unexpected exception caught while fetching column name for #{table_name}.#{column_name} in `column_of_via_arel_table`\n#{e.class}")
    warn(e.backtrace)
    nil
  end

  # The object that knows the type of the attribute +att+.
  #
  # An attribute from the +arel_table+ of a model has a type caster. Return it.
  #
  # A bare +Arel::Table+ or a common table expression has no type caster. We
  # only have the table name, so look up the column in the database.
  #
  # @param att [Arel::Attributes::Attribute] the attribute to describe.
  # @return [ActiveModel::Type::Value, ActiveRecord::ConnectionAdapters::Column, nil]
  #   a type caster or a column. Both respond to +type+. nil if neither is
  #   available.
  def self.type_source_of(att)
    if att.is_a?(Arel::Attribute) && att.respond_to?(:able_to_type_cast?) && att.able_to_type_cast?
      if att.respond_to?(:type_caster) # activerecord >= 6.1
        att.type_caster
      else
        # activerecord <= 6.0 keeps the type caster of an `Arel::Table` out of
        # reach, so ask the model that declares the table.
        model_of(att.relation.table_name)&.type_for_attribute(att.name.to_s)
      end
    elsif att.respond_to?(:relation)
      column_of(att.relation.table_name, att.name.to_s)
    end
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
    nil
  end

  # The type of the column that +att+ points to.
  #
  # @param att [Arel::Attributes::Attribute] the attribute to type.
  # @return [Symbol, nil] the type of the column, or nil if unknown.
  def self.type_of(att)
    type_source_of(att)&.type
  end

  # Whether +model+ is a concrete model that declares +table_name+.
  #
  # @param model [Class] a descendant of +ActiveRecord::Base+.
  # @param table_name [String] the name of a table.
  # @return [Boolean]
  def self.declares_table?(model, table_name)
    !model.abstract_class? && model.table_name == table_name
  rescue StandardError
    # A descendant can raise while computing its `table_name`. Then it's not
    # the model we want.
    false
  end

  # The model that declares +table_name+, if the application loaded that model.
  #
  # +column_of+ only gets a table name, and the table may be in a different
  # database than +ActiveRecord::Base+. The model that declares it knows which
  # pool to use.
  #
  # @param table_name [String] the name of a table.
  # @return [Class, nil] the model that declares the table, or nil if no loaded
  #   model does.
  def self.model_of(table_name)
    if !defined?(ActiveRecord::Base) || !ActiveRecord::Base.respond_to?(:descendants)
      nil
    else
      ActiveRecord::Base.descendants.find { |model| declares_table?(model, table_name) }
    end
  end

  # Schema cache queries for +pool+, as a callable object.
  #
  # Different versions of activerecord keep the schema cache in different
  # places. +columns_hash+ and +data_source_exists?+ both read it, so this
  # method does the version check once.
  #
  # @param pool [ActiveRecord::ConnectionAdapters::ConnectionPool] the pool to
  #   read the schema cache of.
  # @return [Proc, nil] a callable taking a query name and a table name, or nil
  #   if the pool has no schema cache (activerecord < 5.0).
  def self.schema_cache_query(pool)
    if pool.respond_to?(:pool_config)
      if pool.pool_config.respond_to?(:schema_reflection) # activerecord >= 7.1
        reflection = pool.pool_config.schema_reflection
        target = ActiveRecord.version >= Gem::Version.create('7.2') ? pool : pool.connection
        ->(query, table_name) { reflection.public_send(query, target, table_name) }
      else # activerecord < 7.1
        cache = pool.pool_config.schema_cache
        ->(query, table_name) { cache.public_send(query, table_name) }
      end
    elsif pool.respond_to?(:schema_cache) && pool.schema_cache
      cache = pool.schema_cache
      ->(query, table_name) { cache.public_send(query, table_name) }
    elsif pool.respond_to?(:connection) && pool.connection.respond_to?(:schema_cache)
      # activerecord <= 6.0 keeps the cache on the connection, and
      # `pool.schema_cache` is nil there.
      cache = pool.connection.schema_cache
      ->(query, table_name) { cache.public_send(query, table_name) }
    end
  end

  # The column +column_name+ of the table +table_name+.
  #
  # @param table_name [String] the name of a table.
  # @param column_name [String] the name of a column of that table.
  # @return [ActiveRecord::ConnectionAdapters::Column, nil] the column, or nil
  #   if the database has no such column.
  def self.column_of(table_name, column_name)
    model = model_of(table_name)
    pool = (model || ActiveRecord::Base).connection_pool
    use_arel_table = !ActiveRecord::Base.connected?

    if use_arel_table
      column_of_via_arel_table(table_name, column_name)
    else
      query = schema_cache_query(pool)
      if query.nil? # activerecord < 5.0
        column_of_via_arel_table(table_name, column_name)
      elsif model.nil? && !query.call(:data_source_exists?, table_name)
        # If no model declares the name, it may not be a table:
        # `Arel::Table.new` also names a common table expression. Reflecting one
        # of those fails, and on postgres a failed statement kills the
        # surrounding transaction.
        #
        # Check the data source list first. The schema cache keeps it, and never
        # caches a failed reflection.
        nil
      else
        query.call(:columns_hash, table_name)[column_name]
      end
    end
  rescue ActiveRecord::ConnectionNotEstablished
    column_of_via_arel_table(table_name, column_name)
  rescue ActiveRecord::StatementInvalid
    nil
  rescue StandardError => e
    warn("Warning: Unexpected exception caught while fetching column name for #{table_name}.#{column_name} in `column_of`")
    warn(e)
    warn(e.backtrace)
    nil
  end
end
