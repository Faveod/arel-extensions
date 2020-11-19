module ArelExtensions
  module Nodes
    class Substring < Function
      RETURN_TYPE = :string

      def initialize expr
        tab = [convert_to_node(expr[0]), convert_to_node(expr[1])]
        if expr[2]
          tab << convert_to_node(expr[2])
        end
        return super(tab)
      end
    end
  end
end
