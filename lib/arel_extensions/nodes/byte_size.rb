module ArelExtensions
  module Nodes
    class ByteSize < Function
      RETURN_TYPE = :integer

      def initialize(node)
        super([node])
      end
    end
  end
end
