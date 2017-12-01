module ArelExtensions
  module Visitors
    Arel::Visitors::SQLite.class_eval do
      Arel::Visitors::SQLite::DATE_MAPPING = {'d' => '%d', 'm' => '%m', 'w' => '%W', 'y' => '%Y', 'wd' => '%w', 'M' => '%M', 'h' => '%H', 'mn' => '%M', 's' => '%S'}
      Arel::Visitors::SQLite::DATE_FORMAT_DIRECTIVES = { # ISO C / POSIX
        '%Y' => '%Y', '%C' =>   '', '%y' => '%y', '%m' => '%m', '%B' => '%M', '%b' => '%b', '%^b' => '%b', # year, month
        '%d' => '%d', '%e' => '%e', '%j' => '%j', '%w' => '%w', '%A' => '%W', # day, weekday
        '%H' => '%H', '%k' => '%k', '%I' => '%I', '%l' => '%l', '%P' => '%p', '%p' => '%p', # hours
        '%M' => '%M', '%S' => '%S', '%L' =>   '', '%N' => '%f', '%z' => '' # seconds, subseconds
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

      # Date operations
      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "date("
        collector = visit o.expressions.first, collector
        collector << Arel::Visitors::SQLite::COMMA
        collector = visit o.sqlite_value, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
          collector << "strftime('%s', "
          collector = visit o.left, collector
          collector << ") - strftime('%s', "
          collector = visit o.right, collector
        else
          collector << "julianday("
          collector = visit o.left, collector
          collector << ") - julianday("
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        collector << "strftime('#{Arel::Visitors::SQLite::DATE_MAPPING[o.left]}'#{Arel::Visitors::SQLite::COMMA}"
        collector = visit o.right, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "instr("
        collector = visit o.expr, collector
        collector << Arel::Visitors::SQLite::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << "SUBSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::SQLite::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector = visit o.left, collector
        collector << ' IS NULL'
        collector
      end

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << "RANDOM("
        if o.left != nil && o.right != nil 
          collector = visit o.left, collector
          collector << Arel::Visitors::SQLite::COMMA
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << " REGEXP"
        collector = visit o.right, collector
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << " NOT REGEXP "
        collector = visit o.right, collector
        collector
      end

      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "STRFTIME('%w',"
        collector = visit o.date, collector
        collector << ")"
        collector
      end

      # CASE WHEN ROUND(3.42,1) > round(3.42) THEN round(3.42) ELSE round(3.42)-1 END
      # OR CAST(3.14 AS INTEGER)
      def visit_ArelExtensions_Nodes_Floor o, collector
        collector << "CASE WHEN ROUND("
        collector = visit o.left, collector
        collector << ", 1) > ROUND("
        collector = visit o.left, collector
        collector << ") THEN ROUND("
        collector = visit o.left, collector
        collector << ") ELSE ROUND("
        collector = visit o.left, collector
        collector << ") - 1 END"
        collector
      end

      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << "CASE WHEN ROUND("
        collector = visit o.left, collector
        collector << ", 1) > ROUND("
        collector = visit o.left, collector
        collector << ") THEN ROUND("
        collector = visit o.left, collector
        collector << ") + 1 ELSE ROUND("
        collector = visit o.left, collector
        collector << ") END"
        collector
      end

    if Arel::VERSION.to_i < 7
      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        o.left.each_with_index do |row, idx|
          collector << 'SELECT '
          v = Arel::Nodes::Values.new(row, o.cols)
          len = v.expressions.length - 1
          v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value.as(attr.name), collector
              else
                collector << quote(value, attr && column_for(attr)).to_s
                if idx == 0
                  collector << " AS "
                  collector << quote(attr.name)
                end
              end
              collector << Arel::Visitors::SQLite::COMMA unless i == len
          }
          collector << ' UNION ALL ' unless idx == o.left.length - 1
        end
        collector
      end
    else
      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        o.left.each_with_index do |row, idx|
          collector << 'SELECT '
          v = Arel::Nodes::Values.new(row, o.cols)
          len = v.expressions.length - 1
          v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value.as(attr.name), collector
              else
                collector << (attr && attr.able_to_type_cast? ? quote(attr.type_cast_for_database(value)) : quote(value).to_s)
                if idx == 0
                  collector << " AS "
                  collector << quote(attr.name)
                end
              end
              collector << Arel::Visitors::SQLite::COMMA unless i == len
          }
          collector << ' UNION ALL ' unless idx == o.left.length - 1
        end
        collector
      end
    end
    
    
		def visit_ArelExtensions_Nodes_Union o, collector
			if o.left.is_a?(Arel::SelectManager)
				collector = visit o.left.ast, collector
			else
				collector = visit o.left, collector
			end
			collector << " UNION "
			if o.right.is_a?(Arel::SelectManager)
				collector = visit o.right.ast, collector
			else
				collector = visit o.right, collector
			end
			collector
		end

    end
  end
end
