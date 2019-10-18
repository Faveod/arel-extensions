module ArelExtensions
  module Nodes
    class AggregateFunction < Function
      attr_accessor :order, :group

      def initialize node, opts = {}
        @order = opts[:order] ? convert_to_node(opts[:order]) : nil
        @group = opts[:group] ? convert_to_node(opts[:group]) : nil
        super [node]
      end
    end

  end
end
