require 'date'

module ArelExtensions
  module Nodes
    class DateDiff < Function #difference entre colonne date et date string/date
      attr_accessor :left_node_type
      attr_accessor :right_node_type

      @@return_type = :integer # by default...

      def initialize(expr)
        res = []
        col = expr.first
        case col
        when Arel::Nodes::Node, Arel::Attributes::Attribute 
          @left_node_type = type_of_attribute(col)
        when Date
          @left_node_type = :ruby_date
        when DateTime, Time
          @left_node_type = :ruby_time
        end
        res << ([:date, :ruby_date].include?(@left_node_type) ? convert_to_date_node(col) : convert_to_datetime_node(col))
        case expr[1]
        when Arel::Nodes::Node, Arel::Attributes::Attribute 
          @right_node_type = type_of_attribute(expr[1])
        when Date
          @right_node_type = :ruby_date
        when DateTime, Time
          @right_node_type = :ruby_time
        end
        res << ([:date, :ruby_date].include?(@left_node_type) ? convert_to_date_node(expr[1]) : convert_to_datetime_node(expr[1]))
        super res
      end
    end

    class DateAdd < Function
      @@return_type = :date
      attr_accessor :date_type

      def initialize expr
        col = expr.first
        @date_type = type_of_attribute(col)
        tab = expr.map do |arg|
          convert(arg)
        end
        return super(tab)
      end

      def sqlite_value
        v = self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            return Arel::Nodes.build_quoted((v.value >= 0 ? '+' : '-') + v.inspect)
          elsif @date_type == :datetime
            return Arel::Nodes.build_quoted((v.value >= 0 ? '+' : '-') + v.inspect)
          end
        else
          return v
        end
      end

      def mysql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql((v.value >= 0 ? 'INTERVAL ' : 'INTERVAL -') + v.inspect.sub(/s\Z/, ''))
          elsif @date_type == :datetime
            Arel.sql((v.value >= 0 ? 'INTERVAL ' : 'INTERVAL -') + v.inspect.sub(/s\Z/, ''))
          end
        else
          v
        end
      end

      def postgresql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql("INTERVAL '%s'" % v.inspect.sub(/s\Z/, '').upcase)
          elsif @date_type == :datetime
            Arel.sql("INTERVAL '%s'" % v.inspect.sub(/s\Z/, '').upcase)
          end
        else
          return v
        end
      end

      def oracle_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql("INTERVAL '%s' DAY" % v.inspect.to_i)
          elsif @date_type == :datetime
            Arel.sql("INTERVAL '%s' SECOND" % v.to_i)
          end
        else
          v
        end
      end

      def mssql_value(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            v.inspect.to_i
          elsif @date_type == :datetime
            v.to_i
          end
        else
          v
        end
      end

      def mssql_datepart(v = nil)
        v ||= self.expressions.last
        if defined?(ActiveSupport::Duration) && ActiveSupport::Duration === v
          if @date_type == :date
            Arel.sql('day')
          elsif @date_type == :datetime
            Arel.sql('second')
          end
        else
          v
        end
      end

      private
      def convert(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, ActiveSupport::Duration
          object
        when Fixnum, Integer
          object.days
        when DateTime, Time, Date
          raise(ArgumentError, "#{object.class} can not be converted to Fixnum")
        when String
          Arel::Nodes.build_quoted(object)
        else
          raise(ArgumentError, "#{object.class} can not be converted to Fixnum")
        end
      end
    end

    class DateSub < Function #difference entre colonne date et date string/date
      @@return_type = :integer

      def initialize(expr)
        super [expr.first, convert_number(expr[1])]
      end

      def convert_number(object)
        case object
        when Arel::Attributes::Attribute, Arel::Nodes::Node, Fixnum, Integer
          object
        when String
          object.to_i
        else
          raise(ArgumentError, "#{object.class} can not be converted to Number")
        end
      end

    end

  end
end