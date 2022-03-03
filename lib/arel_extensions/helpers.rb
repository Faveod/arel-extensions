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
    begin
      Arel::Table.engine.connection.schema_cache.columns_hash(table_name)[column_name]
    rescue NoMethodError
      nil
    rescue Exception => e
      puts "Failed to fetch column info for #{table_name}.#{column_name} ."
      puts "This should never be reached."
      puts "#{e.class}: #{e}"
      nil
    end
  end

  def self.column_of(table_name, column_name)
    use_arel_table = !ActiveRecord::Base.connected? || \
      (ActiveRecord::Base.connection.pool.respond_to?(:schema_cache) && ActiveRecord::Base.connection.pool.schema_cache.nil?)

    if use_arel_table
      column_of_via_arel_table(table_name, column_name)
    else
      if ActiveRecord::Base.connection.pool.respond_to?(:pool_config)
        ActiveRecord::Base.connection.pool.pool_config.schema_cache.columns_hash(table_name)[column_name]
      elsif ActiveRecord::Base.connection.pool.respond_to?(:schema_cache)
        ActiveRecord::Base.connection.pool.schema_cache.columns_hash(table_name)[column_name]
      else
        puts ">>> We really shouldn't be here #{table_name}.#{column_name}"
        column_of_via_arel_table(table_name, column_name)
      end
    end
  end
end
