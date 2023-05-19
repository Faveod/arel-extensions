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
      }.flatten.reduce([]) { |res, b|
        # concatenate successive literal strings.
        if b.is_a?(Arel::Nodes::Quoted) && b.expr == ''
          res
        elsif res.last && res.last.is_a?(Arel::Nodes::Quoted) && b.is_a?(Arel::Nodes::Quoted)
          res[-1] = Arel.quoted(res.last.expr.to_s + b.expr.to_s)
        else
          res << b
        end
        res
      }
      super(tab)
    end

    def self.new expr
      o = super(expr)
      if o.expressions.length == 1
        o.expressions[0]
      else
        o
      end
    end

    def concat(other)
      Concat.new(self.expressions + [other])
    end
  end

  class GroupConcat < AggregateFunction
    RETURN_TYPE = :string

    attr_accessor :separator

    def initialize node, separator = ', ', **opts
      @separator = convert_to_node(separator)
      super node, **opts
    end
  end
end
