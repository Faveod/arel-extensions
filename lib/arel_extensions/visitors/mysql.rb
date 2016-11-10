module ArelExtensions
  module Visitors
    Arel::Visitors::MySQL.class_eval do
      Arel::Visitors::MySQL::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'WEEK', 'y' => 'YEAR', 'wd' => 'WEEKDAY', 'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'}
      Arel::Visitors::MySQL::DATE_FORMAT_DIRECTIVES = { # ISO C / POSIX
        '%Y' => '%Y', '%C' =>   '', '%y' => '%y', '%m' => '%m', '%B' => '%M', '%b' => '%b', '%^b' => '%b',  # year, month
        '%d' => '%d', '%e' => '%e', '%j' => '%j', '%w' => '%w', '%A' => '%W',                               # day, weekday
        '%H' => '%H', '%k' => '%k', '%I' => '%I', '%l' => '%l', '%P' => '%p', '%p' => '%p',                 # hours
        '%M' => '%i', '%S' => '%S', '%L' =>   '', '%N' => '%f', '%z' => ''
      }

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

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime
          collector << "DATE_FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::MySQL::COMMA
          f = o.iso_format.dup
          Arel::Visitors::MySQL::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
          collector = visit Arel::Nodes.build_quoted(f), collector
          collector << ")"
        when :integer, :float, :decimal
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.right, collector
          collector << ")"
        else
          collector = visit o.left, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
          collector << 'TIMESTAMPDIFF(SECOND, '
        else
          collector << "DATEDIFF("
        end
        collector = visit o.right, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.left, collector
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
        if o.left == 'wd'
          collector << "(WEEKDAY("
          collector = visit o.right, collector
          collector << ") + 1) % 7"
        else
          collector << "#{Arel::Visitors::MySQL::DATE_MAPPING[o.left]}("
          collector = visit o.right, collector
          collector << ")"
        end
        collector
      end


      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "ISNULL("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::MySQL::COMMA
          collector = visit o.right, collector
        end
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
