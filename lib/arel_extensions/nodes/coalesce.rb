module ArelExtensions
  module Nodes
    class Coalesce < Function
      RETURN_TYPE = :string

      attr_accessor :left_node_type

      def return_type
        @left_node_type || self.class.const_get(:RETURN_TYPE)
      end

      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        case expr.first
        when String
          @left_node_type = :string
        when Integer, Float
          @left_node_type = :number
        when ArelExtensions::Nodes::Coalesce, ArelExtensions::Nodes::Function
          @left_node_type = expr.first.respond_to?(:left_node_type) ? expr.first.left_node_type : nil
        when Arel::Nodes::Node, Arel::Attributes::Attribute
          @left_node_type = type_of_attribute(expr.first)
        when Date
          @left_node_type = :ruby_date
        when DateTime, Time
          @left_node_type = :ruby_time
        end
        return super(tab)
      end
    end
  end
end
