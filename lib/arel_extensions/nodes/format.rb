module ArelExtensions
  module Nodes
    class Format < Function
      @@return_type = :string
    	attr_accessor :col_type
    	def initialize expr
	        col = expr.first
	        @col_type = type_of_attribute(col)
        	super [expr.first, convert_to_string_node(expr[1])]
    	end
    end
  end
end