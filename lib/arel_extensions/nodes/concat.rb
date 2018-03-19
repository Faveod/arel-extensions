module ArelExtensions
  module Nodes
    class Concat < Function
      @@return_type = :string
      
      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        return super(tab)
      end

      def +(other)
        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) 
      end
      
      def concat(other)
        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) 
      end

    end

    class GroupConcat < Function
      @@return_type = :string

      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        return super(tab)
      end

      def +(other)
        return ArelExtensions::Nodes::Concat.new([self, other]) 
      end

    end

  end
end
