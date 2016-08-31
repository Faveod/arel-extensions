module ArelExtensions
  module Visitors
    Arel::Visitors::MySQL.class_eval do

      #String functions
      def visit_ArelExtensions_Nodes_IMatches o, collector # insensitive on ASCII
        collector = visit o.left, collector
        collector << ' LIKE '
        collector = visit o.right, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector = visit o.left.lower, collector
        collector << ' NOT LIKE '
        collector = visit o.right.lower(o.right), collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MySQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "GROUP_CONCAT("
        collector = visit o.left, collector
        if o.right
          collector << ' SEPARATOR '
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
          collector << 'TRIM(' # BOTH
          collector = visit o.right, collector
          collector << " FROM "
          collector = visit o.left, collector
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o , collector
          collector << 'TRIM(LEADING '
          collector = visit o.right, collector
          collector << " FROM "
          collector = visit o.left, collector
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o , collector
        collector << 'TRIM(TRAILING '
        collector = visit o.right, collector
        collector << " FROM "
        collector = visit o.left, collector
        collector << ")"
        collector
      end
      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << "DATEDIFF("
        collector = visit o.left, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATE_ADD("
        collector = visit o.left, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.mysql_value(o.right), collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Duration o, collector
        #visit left for period
        if o.left == "d" 
          collector << "DAY("
        elsif(o.left == "m")
          collector << "MONTH("
        elsif (o.left == "w")
          collector << "WEEK("
        elsif (o.left == "y")
          collector << "YEAR("
        end
        #visit right
        collector = visit o.right, collector
        collector << ")"
        collector
      end

     #****************************************************************#

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "IFNULL("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::MySQL::COMMA
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << "REPLACE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MySQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "(WEEKDAY("
        collector = visit o.date, collector
        collector << ") + 1) % 7"
        collector
      end

    end
  end
end
