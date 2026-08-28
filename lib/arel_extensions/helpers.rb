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

  def self.column_of(table_name, column_name)
    pool = ActiveRecord::Base.connection.pool
    use_arel_table = !ActiveRecord::Base.connected? \
      || (pool.respond_to?(:schema_cache) && pool.schema_cache.nil?)

    if use_arel_table
      column_of_via_arel_table(table_name, column_name)
    elsif pool.respond_to?(:pool_config)
      if pool.pool_config.respond_to?(:schema_reflection) # activerecord >= 7.1
        if ActiveRecord.version >= Gem::Version.create('7.2')
          pool.pool_config.schema_reflection.columns_hash(pool, table_name)[column_name]
        else
          pool.pool_config.schema_reflection.columns_hash(ActiveRecord::Base.connection, table_name)[column_name]
        end
      else # activerecord < 7.1
        pool.pool_config.schema_cache.columns_hash(table_name)[column_name]
      end
    elsif pool.respond_to?(:schema_cache) # activerecord < 6.1
      pool.schema_cache.columns_hash(table_name)[column_name]
    else # activerecord < 5.0
      column_of_via_arel_table(table_name, column_name)
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
