module ArelExtensions
  module Nodes
    class Concat < Function
      include ArelExtensions::Math

      def initialize expr
        tab = expr.map do |arg|
          convert(arg)
        end
        return super(tab)
      end

      private
      def convert(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, Fixnum
          object
        when DateTime, Time
          Arel::Nodes.build_quoted(Date.new(object.year, object.month, object.day), self)
        when String
          Arel::Nodes.build_quoted(object)
        when Date
          Arel::Nodes.build_quoted(object, self)
        when ActiveSupport::Duration
          object.to_i
        else
          raise(ArgumentError, "#{object.class} can not be converted to Date")
        end
      end

    end
  end
end
