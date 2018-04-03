module ArelExtensions
  module Nodes
    class Substring < Function
    	RETURN_TYPE = :string

		def initialize expr
			tab = [convert_to_node(expr[0]), convert_to_node(expr[1])]
			if expr[2]
				tab << convert_to_node(expr[2])
#			else
#				tab << expr[0].length
			end
			return super(tab)
		end

#		def +(other)
#			puts "[Substring] : #{other.inspect} (#{self.expressions.inspect})"
#	        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) 
#		end

    end
  end
end
