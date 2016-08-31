module ArelExtensions
  module Visitors
    Arel::Visitors::SQLite.class_eval do

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
        collector << " julianday("
        collector = visit o.left, collector
        collector << ")- julianday("
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        #visit left for period
        if(o.left == "d")
          collector << "strftime('%d',"
        elsif(o.left == "m")
          collector << "strftime('%m',"
        elsif (o.left == "w")
          collector << "strftime('%W',"
        elsif (o.left == "y")
          collector << "strftime('%Y',"
        end
        #visit right
        collector = visit o.right, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "instr("
        collector = visit o.expr, collector
        collector << Arel::Visitors::SQLite::COMMA
        collector = visit o.val, collector
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
        collector << "strftime('%w',"
        collector = visit o.date, collector
        collector << ")"
        collector
      end

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

    end
  end
end