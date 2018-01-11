module ArelExtensions
  module Visitors
    Arel::Visitors::Oracle.class_eval do
      SPECIAL_CHARS = {"\t" => 'CHR(9)', "\n" => 'CHR(10)', "\r" => 'CHR(13)'}
      Arel::Visitors::Oracle::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'IW', 'y' => 'YEAR', 'wd' => 'D', 'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'}
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
        if o.right  && o.right != 'NULL'
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
          if i > 0 && o.left_node_type == :text
            if arg == ''
              collector << 'empty_clob()'
            else
              collector << 'TO_CLOB('
              collector = visit arg, collector
              collector << ')'
            end
          else
            collector = visit arg, collector
          end
        }
        collector << ")"
        collector
      end

      # :date is not possible in Oracle since this type does not really exist
      def visit_ArelExtensions_Nodes_DateDiff o, collector
        lc = o.left_node_type == :ruby_date || o.left_node_type == :ruby_time
        rc = o.right_node_type == :ruby_date || o.right_node_type == :ruby_time
        collector << '('
        collector << 'TO_DATE(' if lc
        collector = visit o.left, collector
        collector << ')' if lc
        collector << " - "
        collector << 'TO_DATE(' if rc
        collector = visit o.right, collector
        collector << ')' if rc
        collector << ')'
        if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
          collector << ' * (CASE WHEN (TRUNC('
          collector << 'TO_DATE(' if lc
          collector = visit o.left, collector
          collector << ')' if lc
          collector << Arel::Visitors::Oracle::COMMA
          collector << "'DDD') = "
          collector << 'TO_DATE(' if lc
          collector = visit o.left, collector
          collector << ')' if lc
          collector << ') THEN 1 ELSE 86400 END)' # converts to seconds
        end
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
        if o.left && o.right
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

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << "SUBSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << 'TRIM(' # BOTH
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector << '(' if o.left.is_a? ArelExtensions::Nodes::Trim
        if o.type_of_attribute(o.left) == :text
          collector << 'dbms_lob.SUBSTR('
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector << 'COALESCE(dbms_lob.GETLENGTH('
          collector = visit o.left, collector
          collector << "), 0)"
          collector << Arel::Visitors::Oracle::COMMA
          collector << '1)'
        else
          collector = visit o.left, collector
        end
        collector << ')' if o.left.is_a? ArelExtensions::Nodes::Trim
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << 'TRIM(LEADING '
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        collector << 'TRIM(TRAILING '
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
        visit o.left.trim.length.coalesce(0).eq(0), collector
      end

      def visit_ArelExtensions_Nodes_NotBlank o, collector
        visit o.left.trim.length.coalesce(0).gt(0), collector
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

        f = o.iso_format.gsub(/\ (\w+)/, ' "\1"')
        Arel::Visitors::Oracle::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
        collector = visit Arel::Nodes.build_quoted(f), collector

        collector << ")"
        collector
      end

      # add primary_key if not present, avoid zip
    if Arel::VERSION.to_i < 7
      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        raise ArgumentError, "missing columns" if o.cols.empty?
        table = collector.value.sub(/\AINSERT INTO/, '')
        into = " INTO#{table}"
        collector = Arel::Collectors::SQLString.new
        collector << "INSERT ALL\n"
        pk_name = @connection.primary_key(o.cols.first.relation.name)
        if pk_name
          pk_missing = !o.cols.detect{|c| c.name == pk_name }
          into.sub!(/\(/, %Q[("#{pk_name.upcase}", ]) if pk_missing
        else
          pk_missing = false
        end
        o.left.each_with_index do |row, idx| # values
          collector << "#{into} VALUES ("
          collector << "NULL, " if pk_missing # expects to have a trigger to set the value before insert
          v = Arel::Nodes::Values.new(row, o.cols)
          len = v.expressions.length - 1
          v.expressions.each_with_index { |value, i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value, collector
              else
                attr = v.columns[i]
                collector << quote(value, attr && column_for(attr)).to_s
              end
              collector << Arel::Visitors::Oracle::COMMA unless i == len
          }
          collector << ')'
        end
        collector << ' SELECT 1 FROM dual'
        collector
      end
    else
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
                collector << (attr && attr.able_to_type_cast? ? quote(attr.type_cast_for_database(value)) : quote(value).to_s)
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
end
