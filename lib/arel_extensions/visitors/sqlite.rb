module ArelExtensions
  module Visitors
    class Arel::Visitors::SQLite
      DATE_MAPPING = {
        'd' => '%d', 'm' => '%m', 'w' => '%W', 'y' => '%Y', 'wd' => '%w', 'M' => '%M',
        'h' => '%H', 'mn' => '%M', 's' => '%S'
      }.freeze

      DATE_FORMAT_DIRECTIVES = { # ISO C / POSIX
        '%Y' => '%Y', '%C' =>   '', '%y' => '%y', '%m' => '%m', '%B' => '%M', '%b' => '%b', '%^b' => '%b', # year, month
        '%d' => '%d', '%e' => '%e', '%j' => '%j', '%w' => '%w', '%A' => '%W', # day, weekday
        '%H' => '%H', '%k' => '%k', '%I' => '%I', '%l' => '%l', '%P' => '%p', '%p' => '%p', # hours
        '%M' => '%M', '%S' => '%S', '%L' =>   '', '%N' => '%f', '%z' => '' # seconds, subseconds
      }.freeze

      NUMBER_COMMA_MAPPING = {
        'fr_FR' => {',' => ' ', '.' => ','}
      }.freeze

      # String functions
      def visit_ArelExtensions_Nodes_ByteSize o, collector
        # sqlite 3.43.0 (2023-08-24) introduced `octet_length`, but we still support older versions.
        # https://sqlite.org/changes.html
        collector << 'length(CAST('
        collector = visit o.expr.coalesce(''), collector
        collector << ' AS BLOB))'
        collector
      end

      def visit_ArelExtensions_Nodes_CharLength o, collector
        collector << 'length('
        collector = visit o.expr.coalesce(''), collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IMatches o, collector # insensitive on ASCII
        collector = visit o.left.ci_collate, collector
        collector << ' LIKE '
        collector = visit o.right.ci_collate, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_AiMatches o, collector
        collector = visit o.left.ai_collate, collector
        collector << ' LIKE '
        collector = visit o.right.ai_collate, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_AiIMatches o, collector
        collector = visit o.left.collate(true, true), collector
        collector << ' LIKE '
        collector = visit o.right.collate(true, true), collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_SMatches o, collector
        collector = visit o.left.collate, collector
        collector << ' LIKE '
        collector = visit o.right.collate, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Collate o, collector
        if o.ai
          collector = visit o.expressions.first, collector
          collector << ' COLLATE NOACCENTS'
        elsif o.ci
          collector = visit o.expressions.first, collector
          collector << ' COLLATE NOCASE'
        else
          collector = visit o.expressions.first, collector
          collector << ' COLLATE BINARY'
        end
        collector
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

      # Date operations
      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << 'date('
        collector = visit o.expressions.first, collector
        collector << COMMA
        collector = visit o.sqlite_value, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        case o.left_node_type
        when :ruby_time, :datetime, :time
          collector << "strftime('%s', "
          collector = visit o.left, collector
          collector << ") - strftime('%s', "
          collector = visit o.right, collector
        else
          collector << 'julianday('
          collector = visit o.left, collector
          collector << ') - julianday('
          collector = visit o.right, collector
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        collector << "strftime('#{DATE_MAPPING[o.left]}'#{COMMA}"
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << 'instr('
        collector = visit o.expr, collector
        collector << COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << '('
        o.expressions.each_with_index { |arg, i|
          collector = visit arg, collector
          collector << ' || ' unless i == o.expressions.length - 1
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << 'SUBSTR('
        o.expressions.each_with_index { |arg, i|
          collector << COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector = visit o.expr, collector
        collector << ' IS NULL'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNotNull o, collector
        collector = visit o.expr, collector
          collector << ' IS NOT NULL'
          collector
      end

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << 'RANDOM('
        if o.left != nil && o.right != nil
          collector = visit o.left, collector
          collector << COMMA
          collector = visit o.right, collector
        end
        collector << ')'
        collector
      end

      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << ' REGEXP'
        collector = visit o.right, collector
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << ' NOT REGEXP '
        collector = visit o.right, collector
        collector
      end

      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "STRFTIME('%w',"
        collector = visit o.date, collector
        collector << ')'
        collector
      end

      # CAST(
      #   CASE
      #     WHEN 3.42 >= 0 THEN CAST(3.42 AS INT)
      #     WHEN CAST(3.42 AS INT) = 3.42 THEN CAST(3.42 AS INT)
      #     ELSE CAST((3.42 - 1.0) AS INT)
      #   END
      #   AS FLOAT
      # )
      def visit_ArelExtensions_Nodes_Floor o, collector
        collector << 'CAST(CASE WHEN '
        collector = visit o.left, collector
        collector << ' >= 0 THEN CAST('
        collector = visit o.left, collector
        collector << ' AS INT) WHEN CAST('
        collector = visit o.left, collector
        collector << ' AS INT) = '
        collector = visit o.left, collector
        collector << ' THEN CAST('
        collector = visit o.left, collector
        collector << ' AS INT) ELSE CAST(('
        collector = visit o.left, collector
        collector << ' - 1.0) AS INT) END AS FLOAT)'
        collector
      end

      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << 'CASE WHEN ROUND('
        collector = visit o.left, collector
        collector << ', 1) > ROUND('
        collector = visit o.left, collector
        collector << ') THEN ROUND('
        collector = visit o.left, collector
        collector << ') + 1 ELSE ROUND('
        collector = visit o.left, collector
        collector << ') END'
        collector
      end

      if Arel::VERSION.to_i < 7
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          o.left.each_with_index do |row, idx|
            collector << 'SELECT '
            len = row.length - 1
            row.zip(o.cols).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value.as(attr.name), collector
              else
                collector << quote(value, attr && column_for(attr)).to_s
                if idx == 0
                  collector << ' AS '
                  collector << quote(attr.name)
                end
              end
                collector << COMMA unless i == len
            }
            collector << ' UNION ALL ' unless idx == o.left.length - 1
          end
          collector
        end
      else
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          o.left.each_with_index do |row, idx|
            collector << 'SELECT '
            len = row.length - 1
            row.zip(o.cols).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value.as(attr.name), collector
              when Integer
                collector << value.to_s
                if idx == 0
                  collector << ' AS '
                  collector << quote(attr.name)
                end
              else
                collector << (attr && attr.able_to_type_cast? ? quote(attr.type_cast_for_database(value)) : quote(value).to_s)
                if idx == 0
                  collector << ' AS '
                  collector << quote(attr.name)
                end
              end
                collector << COMMA unless i == len
            }
            collector << ' UNION ALL ' unless idx == o.left.length - 1
          end
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Union o, collector
        collector =
          if o.left.is_a?(Arel::SelectManager)
            visit o.left.ast, collector
          else
            visit o.left, collector
          end
        collector << ' UNION '
        collector =
          if o.right.is_a?(Arel::SelectManager)
            visit o.right.ast, collector
          else
            visit o.right, collector
          end
        collector
      end

      def visit_ArelExtensions_Nodes_UnionAll o, collector
        collector =
          if o.left.is_a?(Arel::SelectManager)
            visit o.left.ast, collector
          else
            visit o.left, collector
          end
        collector << ' UNION ALL '
        collector =
          if o.right.is_a?(Arel::SelectManager)
            visit o.right.ast, collector
          else
            visit o.right, collector
          end
        collector
      end

      def get_time_converted element
        if element.is_a?(Time)
          Arel::Nodes::NamedFunction.new('STRFTIME', [element, '%H:%M:%S'])
        elsif element.is_a?(Arel::Attributes::Attribute)
          col = Arel.column_of(element.relation.table_name, element.name.to_s)
          if col && (col.type == :time)
            Arel::Nodes::NamedFunction.new('STRFTIME', [element, '%H:%M:%S'])
          else
            element
          end
        else
          element
        end
      end

      remove_method(:visit_Arel_Nodes_GreaterThanOrEqual) rescue nil
      def visit_Arel_Nodes_GreaterThanOrEqual o, collector
        collector = visit get_time_converted(o.left), collector
        collector << ' >= '
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_GreaterThan) rescue nil
      def visit_Arel_Nodes_GreaterThan o, collector
        collector = visit get_time_converted(o.left), collector
        collector << ' > '
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_LessThanOrEqual) rescue nil
      def visit_Arel_Nodes_LessThanOrEqual o, collector
        collector = visit get_time_converted(o.left), collector
        collector << ' <= '
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_LessThan) rescue nil
      def visit_Arel_Nodes_LessThan o, collector
        collector = visit get_time_converted(o.left), collector
        collector << ' < '
        collector = visit get_time_converted(o.right), collector
        collector
      end

      alias_method(:old_visit_Arel_Nodes_As, :visit_Arel_Nodes_As) rescue nil
      def visit_Arel_Nodes_As o, collector
        if o.left.is_a?(Arel::Nodes::Binary)
          collector << '('
          collector = visit o.left, collector
          collector << ')'
        else
          collector = visit o.left, collector
        end
        sep = o.right.size > 1 && o.right[0] == '"' && o.right[-1] == '"' ? '' : '"'
        collector << " AS #{sep}"
        collector = visit o.right, collector
        collector << "#{sep}"
        collector
      end

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        format = Arel::Nodes::NamedFunction.new('printf', [Arel.quoted(o.original_string), o.left])
        locale_map = NUMBER_COMMA_MAPPING[o.locale]
        if locale_map
          format = format.replace(',', locale_map[',']).replace('.', locale_map['.'])
        end
        visit format, collector
        collector
      end
    end
  end
end
