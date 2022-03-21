module ArelExtensions
  module Visitors
    class Arel::Visitors::IBM_DB
      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << 'CEILING('
        collector = visit o.expr, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << 'LTRIM(RTRIM('
        o.expressions.each_with_index { |arg, i|
          collector << COMMA if i != 0
          collector = visit arg, collector
        }
        collector << '))'
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << 'DAY('
        collector = visit o.left, collector
        collector << ','
        if o.right.is_a?(Arel::Attributes::Attribute)
          collector = visit o.right, collector
        else
          collector << "'#{o.right}'"
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        # visit left for period
        if o.left == 'd'
          collector << 'DAY('
        elsif o.left == 'm'
          collector << 'MONTH('
        elsif o.left == 'w'
          collector << 'WEEK'
        elsif o.left == 'y'
          collector << 'YEAR('
        end
        # visit right
        if o.right.is_a?(Arel::Attributes::Attribute)
          collector = visit o.right, collector
        else
          collector << "'#{o.right}'"
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << 'COALESCE('
        collector = visit o.left, collector
        collector << ','
        if (o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.right, collector
        else
          collector << "'#{o.right}'"
        end
        collector << ')'
        collector
      end
    end
  end
end
