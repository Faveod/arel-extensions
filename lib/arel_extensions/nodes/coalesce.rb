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
        when String
          @left_node_type = :string
        when Integer, Float
          @left_node_type = :number
        when ArelExtensions::Nodes::Coalesce, ArelExtensions::Nodes::Function
          @left_node_type = expr.first.try(:left_node_type)
        when Arel::Nodes::Node, Arel::Attributes::Attribute 
          @left_node_type = expr.first
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
