module ArelExtensions
  module Nodes
    class Coalesce < Arel::Nodes::Function
      include Arel::AliasPredication

      def initialize arg , aliaz = nil

        super(arg, aliaz)
      end

      def left
        @expressions.first
      end

      def other
        @expressions.delete_at(0)
        @expressions
      end

    end
  end
end
