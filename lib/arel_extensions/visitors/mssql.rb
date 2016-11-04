module ArelExtensions
  module Visitors
    module MSSQL
      Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'yy', '%C' => '', '%y' => 'yy', '%m' => 'mm', '%B' =>   '', '%b' => '', '%^b' => '',      # year, month
        '%d' => 'dd', '%e' => '', '%j' =>   '', '%w' => 'dw', '%A' => '',                               # day, weekday
        '%H' => 'hh', '%k' => '', '%I' =>   '', '%l' =>   '', '%P' => '', '%p' => '',                 # hours
        '%M' => 'mi', '%S' => 'ss', '%L' => 'ms', '%N' => 'ns', '%z' => 'tz'
      }

      # Math Functions
      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << "CEILING("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

#      def visit_ArelExtensions_Nodes_IsNull o, collector
#        collector << "ISNULL("
#        collector = visit o.left, collector
#        collector << Arel::Visitors::MSSQL::COMMA
#        collector << " 1)"
#        collector
#      end

      # Deprecated
      def visit_ArelExtensions_Nodes_ConcatOld o, collector
        arg = o.left.relation.engine.columns.find{|c| c.name == o.left.name.to_s}.type
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.left, collector
          collector << ' + '
          collector = visit o.right, collector
          collector
        elsif ( arg == :date || arg == :datetime)
          collector << "DATEADD(day"
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.right, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.left, collector
          collector
        else
          collector = visit o.left, collector
          collector << " + '"
          collector = visit o.right, collector
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

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << "DATEDIFF(day"
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      # Deprecated
      def visit_ArelExtensions_Nodes_FormatOld o, collector
        case o.col_type
        when :date, :datetime
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.right, collector
          collector << ")"
        when :integer, :float, :decimal
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.right, collector
          collector << ")"
        else
          collector = visit o.left, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DurationOld o, collector
        #visit left for period
        if(o.left == "d")
          collector << "DAY("
        elsif(o.left == "m")
          collector << "MONTH("
        elsif (o.left == "w")
          collector << "WEEK"
        elsif (o.left == "y")
          collector << "YEAR("
        end
        #visit right
        collector = visit o.right, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Duration o, collector
        case o.left
        when 'wd', 'w'
          collector << "TO_CHAR("
          collector = visit o.right, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit Arel::Nodes.build_quoted(Arel::Visitors::MSSQL::DATE_MAPPING[o.left]), collector
        else
          collector << "DATEPART(#{Arel::Visitors::MSSQL::DATE_MAPPING[o.left]} FROM "
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Length o, collector
        collector << "LEN("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Round o, collector
        collector << "ROUND("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MSSQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        if o.expressions.length == 1
          collector << Arel::Visitors::MSSQL::COMMA
          collector << "0"
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "CHARINDEX("
        collector = visit o.right, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      # TODO manage 2nd argument
      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << "LTRIM(RTRIM("
        collector = visit o.left, collector
        collector << "))"
        collector
      end

      # TODO manage 2nd argument
      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << "LTRIM("
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      # TODO manage 2nd argument
      def visit_ArelExtensions_Nodes_Rtrim o, collector
        collector << "RTRIM("
        collector = visit o.left, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Format o, collector
        collector << "CONCAT("

        t = o.iso_format.split('%')
        t.each_with_index {|str, i|
          if i == 0 && t[0] != '%'
            collector = visit Arel::Nodes.build_quoted(str), collector
            if str.length > 1
              collector << Arel::Visitors::MSSQL::COMMA
              collector = visit Arel::Nodes.build_quoted(str.sub(/\A./, '')), collector
            end
          elsif str.length > 0
            if !Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES['%' + str[0]].blank?
              collector << 'DATEPART('
              collector << Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES['%' + str[0]]
              collector << Arel::Visitors::MSSQL::COMMA
              collector = visit o.left, collector
              collector << ')'
              if str.length > 1
                collector << Arel::Visitors::MSSQL::COMMA
                collector = visit Arel::Nodes.build_quoted(str.sub(/\A./, '')), collector
              end
            end
          end
          collector << Arel::Visitors::MSSQL::COMMA unless i < (t.length - 1)
        }

        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << "REPLACE("
        collector = visit o.expr,collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
 
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end


      # TODO manage case insensitivity
      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = infix_value o, collector, ' LIKE '
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      # TODO manage case insensitivity
      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector = infix_value o, collector, ' NOT LIKE '
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      # SQL Server does not know about REGEXP
      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << "LIKE '%#{o.right}%'"
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << "NOT LIKE '%#{o.right}%'"
        collector
      end

    end
  end
end