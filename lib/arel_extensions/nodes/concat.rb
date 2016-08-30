module ArelExtensions
  module Nodes
    class Concat < Function

      def initialize expr
        tab = expr.map { |arg|
          convert(arg)
        }
        return super(tab)
      end

      def +(other)
        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) 
      end

      private
      def convert(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, Fixnum, Integer
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
          raise(ArgumentError, "#{object.class} can not be converted to CONCAT arg")
        end
      end

    end
  end
end
