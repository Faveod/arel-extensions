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

  # The type of the column that `att` points to.
  #
  # A model makes the attributes of its `arel_table` with a type caster. The
  # type caster knows the type of the column. A query to the database is not
  # necessary. If the model connects to a different database, the query also
  # gets the wrong answer.
  #
  # A bare `Arel::Table` has no type caster. A common table expression has no
  # type caster. For these two, only the name of the table is available. The
  # method must ask the database.
  def self.type_of(att)
    if att.respond_to?(:type_caster) && att.able_to_type_cast?
      att.type_caster&.type
    elsif att.respond_to?(:relation)
      column_of(att.relation.table_name, att.name.to_s)&.type
    end
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
    nil
  end

  # The model that declares `table_name`, if the application loaded that model.
  #
  # `column_of` gets only the name of a table. That table can be in a different
  # database than the database of `ActiveRecord::Base`. If an application has
  # more than one database, the model that declares the table knows the correct
  # pool.
  def self.model_of(table_name)
    return nil unless defined?(ActiveRecord::Base) && ActiveRecord::Base.respond_to?(:descendants)

    ActiveRecord::Base.descendants.find do |model|
      !model.abstract_class? && model.table_name == table_name
    rescue StandardError
      false # A descendant can raise an error for `table_name`. It is not the correct model.
    end
  end

  # Schema cache queries for `pool`, as a callable object.
  #
  # Different versions of activerecord keep the schema cache in different
  # locations. `columns_hash` and `data_source_exists?` both use that cache.
  # Thus this method holds the conditions for the version, one time.
  #
  # The method returns nil if a pool has no schema cache (activerecord < 5.0).
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

  def self.column_of(table_name, column_name)
    model = model_of(table_name)
    pool = (model || ActiveRecord::Base).connection_pool
    use_arel_table = !ActiveRecord::Base.connected?

    return column_of_via_arel_table(table_name, column_name) if use_arel_table

    query = schema_cache_query(pool)

    return column_of_via_arel_table(table_name, column_name) if query.nil? # activerecord < 5.0

    query.call(:columns_hash, table_name)[column_name]
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
