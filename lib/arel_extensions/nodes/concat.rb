module ArelExtensions::Nodes
  class Concat < Function
    RETURN_TYPE = :string

    def initialize expr
      tab = expr.map { |arg|
        # flatten nested concats.
        node = convert_to_node(arg)
        if node.is_a?(Concat)
          node.expressions
        else
          node
        end
      }.flatten.reduce([]) { | res, b |
        # concatenate successive literal strings.
        if res.last && res.last.is_a?(Arel::Nodes::Quoted) && b.is_a?(Arel::Nodes::Quoted)
          res[-1] = quotedArel::Nodes.build_quoted(res.last.expr + b.expr)
        else
          res << b
        end
        res
      }
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
