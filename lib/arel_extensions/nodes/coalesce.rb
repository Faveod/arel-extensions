module ArelExtensions
  module Nodes
    class Coalesce < Function

      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        return super(tab)
      end
      
    end
  end
end
