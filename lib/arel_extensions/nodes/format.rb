module ArelExtensions
  module Nodes
    class Format < Function
    	attr_accessor :col_type
    	def initialize expr
	        col = expr.first
	        @col_type = Arel::Table.engine.connection.schema_cache.columns_hash(col.relation.table_name)[col.name.to_s].type
	        tab = expr.map do |arg|
	          convert(arg)
	        end
        	return super(tab)
    	end
    end
  end
end