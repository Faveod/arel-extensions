module ArelExtensions
  module Nodes
    class LevenshteinDistance < Function
    	RETURN_TYPE = :number
		
		def initialize expr
		  super [convert_to_node(expr.first), Arel::Nodes.build_quoted(expr[1])]		  
		end
    end
  end
end
