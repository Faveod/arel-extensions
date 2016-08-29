module ArelExtensions
  module Nodes
    class Function < Arel::Nodes::Function
      include Arel::Math
      include Arel::Expressions

    	# overrides as to make new Node like AliasPredication
      def as other
        Arel::Nodes::As.new(self, Arel.sql(other))
      end

      def expr
       	@expressions.first
      end

      def left
        @expressions.first
      end

      def right
        @expressions.last
      end

    end
  end
end