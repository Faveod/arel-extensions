module ArelExtensions
  module Visitors
    Arel::Visitors::MySQL.class_eval do


      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << "DATEDIFF("
        collector = visit o.left, collector
        collector << ","
        collector = visit o.right, collector
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
          collector << "WEEK("
        elsif (o.left == "y")
          collector << "YEAR("
        end
        #visit right
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.right, collector
        else
          collector << "#{o.right}"
        end
        collector << ")"
        collector
      end

     #****************************************************************#
      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MySQL::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        if(o.left.is_a?(Arel::Attributes::Attribute))
          collector = visit o.left, collector
        else
          collector << "#{o.left}"
        end
           o.other.each { |a|
          collector << ","
          if(a.is_a?(Arel::Attributes::Attribute))
            collector = visit a, collector
          else
            collector << "#{a}"
          end
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Isnull o, collector
          collector << "IFNULL("
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


       def visit_ArelExtensions_Nodes_Replace o, collector
         collector << "REPLACE("
         collector = visit o.expr,collector
         collector << ","
         if(o.left.is_a?(Arel::Attributes::Attribute))
           collector = visit o.left, collector
         else
           collector << "'#{o.left}'"
         end
         collector << ","
         if(o.right.is_a?(Arel::Attributes::Attribute))
           collector = visit o.right, collector
         else
           collector << "'#{o.right}'"
         end
         collector << ")"
         collector
       end


      def visit_ArelExtensions_Nodes_Soundex o, collector
        collector << "SOUNDEX("
       if((o.expr).is_a?(Arel::Attributes::Attribute))
        collector = visit o.expr, collector
      else
          collector << "'#{o.expr}'"
       end
        collector << ")"
        collector
      end



      def visit_ArelExtensions_Nodes_Trim o , collector
          collector << 'TRIM(BOTH '
          if(o.right.is_a?(Arel::Attributes::Attribute))
            collector = visit o.right, collector
          else
            collector << "'#{o.right}'"
          end
          collector << " FROM "
          collector = visit o.left, collector

          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o , collector
          collector << 'TRIM(LEADING '
          if(o.right.is_a?(Arel::Attributes::Attribute))
            collector = visit o.right, collector
          else
            collector << "'#{o.right}'"
          end
          collector << " FROM "
          collector = visit o.left, collector

          collector << ")"
          collector
      end


      def visit_ArelExtensions_Nodes_Rtrim o , collector
          collector << 'TRIM(TRAILING '
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.right, collector
        else
          collector << "'#{o.right}'"
        end
        collector << " FROM "
        collector = visit o.left, collector

        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "(WEEKDAY("
        if((o.date).is_a?(Arel::Attributes::Attribute))
          collector = visit o.date, collector
        else
          collector << "'#{o.date}'"
        end
        collector << ") + 1) % 7"
        collector
      end

    end
  end
end
