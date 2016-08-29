module ArelExtensions
  module Nodes
    class Rand < Function

      def initialize(seed = nil)
        if seed && seed.length == 1
          super seed
        else
          super []
        end
      end

      def left
        @expressions.first
      end

      def right
        @expressions[1]
      end

    end
  end
end
