module ArelExtensions
  module Nodes
    class Length < Function
      RETURN_TYPE = :integer
      attr_accessor :bytewise

      def initialize(node, bytewise = true)
        @bytewise = bytewise
        super([node])
      end
    end
  end
end
