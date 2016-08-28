module ArelExtensions
  module Nodes
    class FindInSet < Function

      def left
        @expressions.first
      end


      def right
        @expressions[1]
      end

    end
  end
end
