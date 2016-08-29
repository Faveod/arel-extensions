module ArelExtensions
  module Nodes
    class Replace < Arel::Nodes::Function


      def initialize expr, left, right, aliaz = nil
        tab = Array.new
        tab << expr
        tab << left
        tab << right
        super(tab, aliaz)
      end


      def expr
        @expressions.first
      end


      def left
        @expressions[1]
      end


      def right
        @expressions[2]
      end


      def as other
        Arel::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other)
      end

    end
  end
end
