require 'arel_extensions/predications'

# This is required for rails 6.1
# See https://github.com/thoughtbot/shoulda-matchers/issues/335
if !Array.respond_to?(:wrap)
  require 'active_support/core_ext/array/wrap'
end

module ArelExtensions
  module Nodes
    class Function < Arel::Nodes::Function
      include Arel::Math
      include Arel::Expressions
      include Arel::OrderPredications
      include ArelExtensions::Predications

      RETURN_TYPE = :string # by default...

      # Support multibyte string if they are available.
      MBSTRING =
        defined?(ActiveSupport::Multibyte::Chars) ? ActiveSupport::Multibyte::Chars : String

      # overrides as to make new Node like AliasPredication

      def return_type
        self.class.const_get(:RETURN_TYPE)
      end

      def as other
        res = Arel::Nodes::As.new(self.clone, Arel.sql(other))
        self.alias = Arel.sql(other)
        res
      end

      def expr
        @expressions.first
      end

      def left
        @expressions.first
      end

      def right
        @expressions[1]
      end

      def ==(other)
        Arel::Nodes::Equality.new self, Arel.quoted(other, self)
      end

      def !=(other)
        Arel::Nodes::NotEqual.new self, Arel.quoted(other, self)
      end

      def type_of_attribute(att)
        case att
        when Arel::Attributes::Attribute
          Arel.column_of(att.relation.table_name, att.name.to_s)&.type || att
        when ArelExtensions::Nodes::Function
          att.return_type
          #        else
          #          nil
        end
      end

      def convert_to_node(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, Integer
          object
        when DateTime
          Arel.quoted(object, self)
        when Time
          Arel.quoted(object.strftime('%H:%M:%S'), self)
        when MBSTRING, String, Symbol
          Arel.quoted(object.to_s)
        when Date
          Arel.quoted(object.to_s, self)
        when NilClass
          Arel.sql('NULL')
        when ActiveSupport::Duration
          Arel.sql(object.to_i)
        when Array
          Arel.grouping(object.map{|e| convert_to_node(e)})
        else
          raise(ArgumentError, "#{object.class} cannot be converted to CONCAT arg")
        end
      end

      def convert_to_string_node(object)
        case object
        when Arel::Nodes::Node
          object
        when Integer
          Arel.quoted(object.to_s)
        when Arel::Attributes::Attribute
          case self.type_of_attribute(object)
          when :date
            ArelExtensions::Nodes::Format.new [object, 'yyyy-mm-dd']
          when :time
            ArelExtensions::Nodes::Format.new [object, '%H:%M:%S']
          else
            object
          end
        when DateTime
          Arel.quoted(object, self)
        when Time
          Arel.quoted(object.strftime('%H:%M:%S'), self)
        when MBSTRING, String
          Arel.quoted(object.to_s)
        when Date
          Arel.quoted(object, self)
        when NilClass
          Arel.sql(nil)
        when ActiveSupport::Duration
          Arel.quoted(object.to_i.to_s)
        else
          raise(ArgumentError, "#{object.class} cannot be converted to CONCAT arg")
        end
      end

      def convert_to_date_node(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node
          object
        when DateTime, Time
          Arel.quoted(Date.new(object.year, object.month, object.day), self)
        when MBSTRING, String
          Arel.quoted(Date.parse(object.to_s), self)
        when Date
          Arel.quoted(object, self)
        else
          raise(ArgumentError, "#{object.class} cannot be converted to Date")
        end
      end

      def convert_to_datetime_node(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node
          object
        when DateTime, Time
          Arel.quoted(object, self)
        when MBSTRING, String
          Arel.quoted(Time.parse(object.to_s), self)
        when Date
          Arel.quoted(Time.utc(object.year, object.month, object.day, 0, 0, 0), self)
        else
          raise(ArgumentError, "#{object.class} cannot be converted to Datetime")
        end
      end

      def convert_to_number(object)
        case object
        when ArelExtensions::Nodes::Duration
          object.with_interval = true
          object
        when Arel::Attributes::Attribute, Arel::Nodes::Node
          object
        when Integer
          object.to_i.abs
        when DateTime, Date, Time, String, ActiveSupport::Duration
          object.to_i.abs
        when NilClass
          0
        else
          raise(ArgumentError, "#{object.class} cannot be converted to NUMBER arg")
        end
      end
    end
  end
end
