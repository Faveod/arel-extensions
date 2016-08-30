module ArelExtensions
  module Visitors
    Arel::Visitors::PostgreSQL.class_eval do

      def visit_ArelExtensions_Nodes_DateDiff o, collector

        collector = visit o.left, collector
        collector << " -"
        if(o.right.is_a?(Arel::Attributes::Attribute))
          collector = visit o.left, collector
        else
          collector << " date '#{o.right}'"
        end
        collector
      end


    def visit_ArelExtensions_Nodes_Duration o, collector
      #visit left for period
      if(o.left == "d")
        collector << "EXTRACT(DAY FROM"
      elsif(o.left == "m")
        collector << "EXTRACT(MONTH FROM "
      elsif (o.left == "w")
        collector << "EXTRACT(WEEK FROM"
      elsif (o.left == "y")
        collector << "EXTRACT(YEAR FROM"
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


    def visit_ArelExtensions_Nodes_Locate o, collector
      collector << "position("
      if(o.val.is_a?(Arel::Attributes::Attribute))
        collector = visit o.val, collector
      else
        collector << "'#{o.val}'"
      end
      collector << " IN "
      collector = visit o.expr, collector
      collector << ")"
      collector
    end

    def visit_ArelExtensions_Nodes_Isnull o, collector
      collector << "coalesce("
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


     def visit_ArelExtensions_Nodes_Rand o, collector
       collector << "random("
       if(o.left != nil && o.right != nil)
       collector << "'#{o.left}'"
       collector << ","
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


    remove_method(:visit_Arel_Nodes_Regexp) rescue nil
    def visit_Arel_Nodes_Regexp o, collector
      collector = visit o.left, collector
      collector << " ~ "
      collector << "'#{o.right}'"
      collector
    end

    remove_method(:visit_Arel_Nodes_NotRegexp) rescue nil
    def visit_Arel_Nodes_NotRegexp o, collector
      collector = visit o.left, collector
      collector << " !~ "
      collector << "'#{o.right}'"
      collector
    end


    def visit_ArelExtensions_Nodes_Soundex o, collector
      collector << "soundex("
     if((o.expr).is_a?(Arel::Attributes::Attribute))
      collector = visit o.expr, collector
    else
        collector << "'#{o.expr}'"
     end
      collector << ")"
      collector
    end


    def visit_ArelExtensions_Nodes_Sum o, collector
      collector << "sum("
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
        collector << "date_part('dow', "
        if((o.date).is_a?(Arel::Attributes::Attribute))
          collector = visit o.date, collector
        else
          collector << "'#{o.date}'"
        end
        collector << ")"
        collector
      end

    end
  end
end