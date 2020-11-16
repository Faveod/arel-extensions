module ArelExtensions
  module Nodes
    class Power < Function
      RETURN_TYPE = :number

      def initialize expr
        super [convert_to_node(expr.first), convert_to_number(expr[1])]
      end
    end
  end
end
