module ArelExtensions
  module Nodes
    class Coalesce < Function
      include ArelExtensions::Math
      attr_accessor :left_node_type


      def initialize expr
        tab = expr.map { |arg|
          convert_to_node(arg)
        }
        case expr.first
        when Arel::Nodes::Node, Arel::Attributes::Attribute 
          @left_node_type = type_of_attribute(expr.first)
        when String
          @left_node_type = :string
        when ArelExtensions::Nodes::Coalesce
          @left_node_type = expr.first.left_node_type
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
