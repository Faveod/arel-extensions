module ArelExtensions
  module Visitors
    module MSSQL
      Arel::Visitors::MSSQL::DATE_MAPPING = {'d' => 'day', 'm' => 'month', 'y' => 'year', 'wd' => 'weekday', 'w' => 'week', 'h' => 'hour', 'mn' => 'minute', 's' => 'second'}
      Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'YYYY', '%C' => '', '%y' => 'YY', '%m' => 'MM', '%B' =>   '', '%b' => '', '%^b' => '', # year, month
        '%d' => 'DD', '%e' => '', '%j' =>   '', '%w' => 'dw', '%A' => '', # day, weekday
        '%H' => 'hh', '%k' => '', '%I' =>   '', '%l' =>   '', '%P' => '', '%p' => '', # hours
        '%M' => 'mi', '%S' => 'ss', '%L' => 'ms', '%N' => 'ns', '%z' => 'tz'
      }
      # TODO; all others... http://www.sql-server-helper.com/tips/date-formats.aspx
      Arel::Visitors::MSSQL::DATE_CONVERT_FORMATS = {
        'YYYY-MM-DD' => 120,
        'YY-MM-DD'  => 120,
        'MM/DD/YYYY' => 101,
        'MM-DD-YYYY' => 110,
        'YYYY/MM/DD' => 111,
        'DD-MM-YYYY' => 105,
        'DD-MM-YY'   => 5,
        'DD.MM.YYYY' => 104,
        'YYYY-MM-DDTHH:MM:SS:MMM' => 126
      }

      # Math Functions
      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << "CEILING("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "("
        collector = visit o.left, collector
#         collector << Arel::Visitors::MSSQL::COMMA
        collector << " IS NULL)"
        collector
      end

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
          collector << Arel::Visitors::MSSQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                        'DATEDIFF(second'
                    else
                      'DATEDIFF(day'
                    end
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.right, collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATEADD("
        collector << o.mssql_datepart(o.right)
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.mssql_value(o.right), collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        conv = ['h', 'mn', 's'].include?(o.left)
        collector << 'DATEPART('
        collector << Arel::Visitors::MSSQL::DATE_MAPPING[o.left]
        collector << Arel::Visitors::MSSQL::COMMA
        collector << 'CONVERT(datetime,' if conv
        collector = visit o.right, collector
        collector << ')' if conv
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

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << 'SUBSTRING('
        collector = visit o.expressions[0], collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = visit o.expressions[1], collector
        collector << Arel::Visitors::MSSQL::COMMA
        collector = o.expressions[2] ? visit(o.expressions[2], collector) : visit(o.expressions[0].length, collector)
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        if o.right
          collector << "REPLACE(REPLACE(LTRIM(RTRIM(REPLACE(REPLACE("
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' '))), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << "LTRIM(RTRIM("
          collector = visit o.left, collector
          collector << "))"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        if o.right
          collector << "REPLACE(REPLACE(LTRIM(REPLACE(REPLACE("
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << "LTRIM("
          collector = visit o.left, collector
          collector << ")"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        if o.right
          collector << "REPLACE(REPLACE(RTRIM(REPLACE(REPLACE("
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << "RTRIM("
          collector = visit o.left, collector
          collector << ")"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
        visit o.left.trim.length.eq(0), collector
      end

      def visit_ArelExtensions_Nodes_NotBlank o, collector
        visit o.left.trim.length.gt(0), collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        f = o.iso_format.dup
        Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
        if Arel::Visitors::MSSQL::DATE_CONVERT_FORMATS[f]
          collector << "CONVERT(VARCHAR(#{f.length})"
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.left, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector << Arel::Visitors::MSSQL::DATE_CONVERT_FORMATS[f].to_s
          collector << ')'
          collector
        else
          collector << "("
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
                collector << 'LTRIM(STR(DATEPART('
                collector << Arel::Visitors::MSSQL::DATE_FORMAT_DIRECTIVES['%' + str[0]]
                collector << Arel::Visitors::MSSQL::COMMA
                collector = visit o.left, collector
                collector << ')))'
                if str.length > 1
                  collector << ' + '
                  collector = visit Arel::Nodes.build_quoted(str.sub(/\A./, '')), collector
                end
              end
            end
            collector << ' + ' if t[i + 1]
          }

          collector << ')'
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << "REPLACE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MSSQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_FindInSet o, collector
        collector << "dbo.FIND_IN_SET("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MSSQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      # TODO; manage case insensitivity
      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = infix_value o, collector, ' LIKE '
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      # TODO; manage case insensitivity
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

      # TODO; 
      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "(LISTAGG("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit o.right, collector
        end
        collector << ") WITHIN GROUP (ORDER BY "
        collector = visit o.left, collector
        collector << "))"
        collector
      end

    end
  end
end
