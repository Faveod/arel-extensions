require 'arel_extensions/visitors/to_sql'
require 'arel_extensions/visitors/mysql'
require 'arel_extensions/visitors/oracle'
require 'arel_extensions/visitors/oracle12'
require 'arel_extensions/visitors/postgresql'
require 'arel_extensions/visitors/sqlite'
require 'arel_extensions/visitors/mssql'

Arel::Visitors::MSSQL.class_eval do
	include ArelExtensions::Visitors::MSSQL
	
	alias_method :old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement
	def visit_Arel_Nodes_SelectStatement o, collector	
		if !collector.value.blank? && o.limit.blank? && o.offset.blank? 		
			o = o.dup
			o.orders = []
		end
		old_visit_Arel_Nodes_SelectStatement(o,collector)
	end	
end

begin 
	require 'arel_sqlserver'
	if Arel::VERSION.to_i == 6
		if Arel::Visitors::VISITORS['sqlserver'] && Arel::Visitors::VISITORS['sqlserver'] != Arel::Visitors::MSSQL
			Arel::Visitors::VISITORS['sqlserver'].class_eval do
		  		include ArelExtensions::Visitors::MSSQL
		  		
		  		alias_method :old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement
				def visit_Arel_Nodes_SelectStatement o, collector	
					if !collector.value.blank? && o.limit.blank? && o.offset.blank? 					
						o = o.dup
						o.orders = []
					end
					old_visit_Arel_Nodes_SelectStatement(o,collector)
				end	
				
				def primary_Key_From_Table t
					return unless t
					column_name = @connection.schema_cache.primary_keys(t.name) ||
					  @connection.schema_cache.columns_hash(t.name).first.try(:second).try(:name)
					column_name ? t[column_name] : nil
				end
			end 
		end
	end
rescue LoadError
rescue => e
	e
end
