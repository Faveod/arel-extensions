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
  rescue => e
    warn("Warning: Unexpected exception caught while fetching column name for #{table_name}.#{column_name} in `column_of_via_arel_table`\n#{e.class}: #{e}")
    nil
  end

  def self.column_of(table_name, column_name)
    pool = ActiveRecord::Base.connection.pool
    use_arel_table = !ActiveRecord::Base.connected? || \
      (pool.respond_to?(:schema_cache) && pool.schema_cache.nil?)

    if use_arel_table
      column_of_via_arel_table(table_name, column_name)
    else
      if pool.respond_to?(:pool_config)
        pool.pool_config.schema_cache.columns_hash(table_name)[column_name]
      elsif pool.respond_to?(:schema_cache)
        pool.schema_cache.columns_hash(table_name)[column_name]
      else
        column_of_via_arel_table(table_name, column_name)
      end
    end
  rescue ActiveRecord::ConnectionNotEstablished
    column_of_via_arel_table(table_name, column_name)
  rescue ActiveRecord::StatementInvalid
    nil
  rescue => e
    warn("Warning: Unexpected exception caught while fetching column name for #{table_name}.#{column_name} in `column_of`\n#{e.class}: #{e}")
    nil
  end
end
