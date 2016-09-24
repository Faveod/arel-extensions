module ArelExtensions
  module Visitors
    Arel::Visitors::Oracle.class_eval do
      Arel::Visitors::Oracle::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'IW', 'y' => 'YEAR', 'wd' => 'D'}
      Arel::Visitors::Oracle::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'IYYY', '%C' => 'CC', '%y' => 'YY', '%m' => 'MM', '%B' => 'Month', '%^B' => 'MONTH', '%b' => 'Mon', '%^b' => 'MON',
        '%d' => 'DD', '%e' => 'FMDD', '%j' => 'DDD', '%w' => '', '%A' => 'Day',                             # day, weekday
        '%H' => 'HH24', '%k' => '', '%I' => 'HH', '%l' => '', '%P' => 'am', '%p' => 'AM',                   # hours
        '%M' => 'MI', '%S' => 'SS', '%L' => 'MS', '%N' => 'US', '%z' => 'tz'                                # seconds, subseconds
      }

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << '('
        o.expressions.each_with_index { |arg, i|
          collector = visit o.convert_to_string_node(arg), collector
          collector << ' || ' unless i == o.expressions.length - 1
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = visit o.left.lower, collector
        collector << ' LIKE '
        collector = visit o.right.lower(o.right), collector
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

      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << '('
        collector << 'TO_DATE(' unless o.left_node_type == :date || o.left_node_type == :datetime
        collector = visit o.left, collector
        collector << ')' unless o.left_node_type == :date || o.left_node_type == :datetime
        collector << " - "
        collector << 'TO_DATE(' unless o.right_node_type == :date || o.right_node_type == :datetime
        collector = visit o.right, collector
        collector << ')' unless o.right_node_type == :date || o.right_node_type == :datetime
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        case o.left
        when 'wd', 'w'
          collector << "TO_CHAR("
          collector = visit o.right, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit Arel::Nodes.build_quoted(Arel::Visitors::Oracle::DATE_MAPPING[o.left]), collector
        else
          collector << "EXTRACT(#{Arel::Visitors::Oracle::DATE_MAPPING[o.left]} FROM "
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Length o, collector
        collector << "LENGTH("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector = visit o.left, collector
        collector << ' IS NULL'
        collector
      end

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << "DBMS_RANDOM.VALUE("
        if(o.left != nil && o.right != nil)
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_Arel_Nodes_Regexp o, collector
        collector << " REGEXP_LIKE("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector << " NOT REGEXP_LIKE("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "INSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << 'TRIM(' # BOTH
        case o.right.expr
        when "\t"
          collector << 'CHR(9)'
        when "\n"
          collector << 'CHR(10)'
        when "\r"
          collector << 'CHR(13)'
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector << '(' if o.left.is_a? ArelExtensions::Nodes::Trim
        collector = visit o.left, collector
        collector << ')' if o.left.is_a? ArelExtensions::Nodes::Trim
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << 'TRIM(LEADING '
        collector = visit o.right, collector
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        collector << 'TRIM(TRAILING '
        collector = visit o.right, collector
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
        collector << '(CASE WHEN ('
        collector = visit o.left, collector
        collector << " = '') THEN 1 ELSE 0 END)"
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << '('
        collector = visit o.left, collector
        collector << (o.right.value >= 0 ? ' + ' : ' - ')
        collector = visit o.oracle_value(o.right), collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        collector << "TO_CHAR("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA

        f = o.iso_format.dup
        Arel::Visitors::Oracle::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
        collector = visit Arel::Nodes.build_quoted(f), collector

        collector << ")"
        collector
      end

      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        table = collector.value.sub(/\AINSERT INTO/, '')
        into = " INTO#{table}"
        collector = Arel::Collectors::SQLString.new
        collector << "INSERT ALL\n"
        o.left.each_with_index do |row, idx|
          collector << "#{into} VALUES ("
          v = Arel::Nodes::Values.new(row, o.cols)
          len = v.expressions.length - 1
          v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value, collector
              else
                collector << quote(value, attr && column_for(attr)).to_s
              end
              collector << Arel::Visitors::Oracle::COMMA unless i == len
          }
          collector << ')'
        end
        collector << ' SELECT 1 FROM dual'
        collector
      end
    end
  end
end