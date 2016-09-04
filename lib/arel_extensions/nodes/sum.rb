module ArelExtensions
  module Nodes
    class Sum < Function
      @@return_type = :number

      def initialize other, aliaz = nil
        tab = Array.new
        tab << other
        super(tab, aliaz)
      end

      def expr
        @expressions.first
      end


      def as other
        Arel::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other)
      end

    end
  end
end
