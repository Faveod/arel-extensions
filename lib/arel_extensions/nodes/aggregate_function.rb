module ArelExtensions
  module Nodes
    class AggregateFunction < Function
      attr_accessor :order, :group

      def initialize node, **opts
        @order = Array(opts[:order]).map{|e| convert_to_node(e)}
        @group = Array(opts[:group]).map{|e| convert_to_node(e)}
        super [node]
      end
    end
  end
end
