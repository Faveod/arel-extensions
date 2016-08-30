module ArelExtensions
  module Nodes
    class Round < Function

      def initialize expr
      	if expr && expr.length == 1
      		super [convert_to_node(expr.first)]
      	else
      		super [convert_to_node(expr.first), convert_to_number(expr[1])]
      	end
      end

    end
  end
end
