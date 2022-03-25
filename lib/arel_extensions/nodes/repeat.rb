module ArelExtensions
  module Nodes
    class Repeat < Function
      RETURN_TYPE = :string

      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        super(tab)
      end

      def +(other)
        ArelExtensions::Nodes::Concat.new(self.expressions + [other])
      end
    end
  end
end
