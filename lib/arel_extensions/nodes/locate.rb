module ArelExtensions
  module Nodes
    class Locate < Function
    	@@return_type = :integer

		def initialize expr
			tab = expr.map do |arg|
			  convert_to_node(arg)
			end
			return super(tab)
		end

    end
  end
end
