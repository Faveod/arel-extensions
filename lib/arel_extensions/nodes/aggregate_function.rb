module ArelExtensions
  module Nodes
    class AggregateFunction < Function
      attr_accessor :options

      def initialize node, opts = {}
        @options = opts
        super [node]
      end
    end

  end
end
