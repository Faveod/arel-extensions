module ArelExtensions
  module Visitors
    Arel::Visitors::MSSQL.class_eval do
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

      def visit_ArelExtensions_Nodes_Concat o, collector
        arg = o.left.relation.engine.columns.find{|c| c.name == o.left.name.to_s}.type
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.left, collector
          collector << ' + '
          collector = visit o.right, collector
          collector
        elsif ( arg == :date || arg == :datetime)
          collector << "DATEADD(day,#{o.right},"
          collector = visit o.left, collector
          collector
        else
          collector = visit o.left, collector
          collector << " + '"
          collector = visit o.right, collector
          collector
        end
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << "DATEDIFF(day,"
        collector = visit o.left, collector
        collector<< ","
        collector = visit o.right, collector

        end
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Duration o, collector
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
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.right, collector
        else
          collector << "'#{o.right}'"
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


      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "CHARINDEX("
        collector = visit o.val, collector
       collector << ","
       collector = visit o.expr, collector
       collector << ")"
       collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        collector << "CONCAT("

        t = o.iso_format.split('%')
        t.each_with_index {|str, i|
          if i == 0 && f[0] != '%'
            collector = visit Arel::Nodes.build_quoted(str), collector
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
 
         collector << ","
         if(o.right.is_a?(Arel::Attributes::Attribute))
           collector = visit o.right, collector
         else
           collector << "'#{o.right}'"
         end
         collector << ")"
         collector
      end


      # SQL Server does not know about REGEXP
      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << "LIKE '% #{o.right}%'"
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << "NOT LIKE '% #{o.right}%'"
        collector
      end

    end
  end
end
