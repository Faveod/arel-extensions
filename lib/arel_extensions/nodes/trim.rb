module ArelExtensions
  module Nodes
    class Trim < Function
      RETURN_TYPE = :string

      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        return super(tab)
      end

      def +(other)
        return ArelExtensions::Nodes::Concat.new(self.expressions + [other])
      end
    end

    class Ltrim < Trim
      RETURN_TYPE = :string
    end

    class Rtrim < Trim
      RETURN_TYPE = :string
    end
  end
end
