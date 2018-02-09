module ArelExtensions
  module Nodes
    class Power < Function
    	@@return_type = :number
		
		def initialize expr
		  super [convert_to_node(expr.first), convert_to_number(expr[1])]		  
		end
    end
  end
end
