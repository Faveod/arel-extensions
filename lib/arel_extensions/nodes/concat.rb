module ArelExtensions::Nodes
  class Concat < Function
    RETURN_TYPE = :string

    def initialize expr
      tab = expr.map { |arg|
        node = convert_to_node(arg)
        if node.is_a?(Concat)
          node.expressions
        else
          node
        end
      }.flatten
      super(tab)
    end

    #def +(other)
    #  Concat.new(self.expressions + [other])
    #end

    def concat(other)
      Concat.new(self.expressions + [other])
    end

  end

  class GroupConcat < Function
    RETURN_TYPE = :string

    def initialize expr
      tab = expr.map { |arg|
        convert_to_node(arg)
      }
      super(tab)
    end

    #def +(other)
    #  return Concat.new([self, other])
    #end

  end
end
