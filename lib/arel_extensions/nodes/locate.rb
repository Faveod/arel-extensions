module ArelExtensions
  module Nodes
    class Locate < Function

		def initialize expr
			tab = expr.map do |arg|
			  convert_to_node(arg)
			end
			return super(tab)
		end

		def +(other)
	        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) 
		end

    end
  end
end
