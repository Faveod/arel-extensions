module ArelExtensions
  module Nodes
    class Duration < Function
      @@return_type = :number

      def initialize left, right, aliaz = nil
        tab = Array.new
        tab << left
        tab << right
        super(tab, aliaz)
      end


      def left
        @expressions.first
      end


      def right
        @expressions[1]
      end


      def as other
        Arel::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other.to_s)
      end

    end
  end
end
