module ArelExtensions
  module Nodes
    class CharLength < Function
      RETURN_TYPE = :integer

      def initialize(node)
        super([node])
      end
    end
  end
end
