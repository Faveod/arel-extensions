module ArelExtensions
  module Visitors
    Arel::Visitors::Oracle.class_eval do

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
        collector << "LISTAGG("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        collector = visit o.left, collector
        o.other.each { |a|
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit a, collector
        }
        collector << ")"
        collector
      end

  def visit_ArelExtensions_Nodes_DateDiff o, collector
    collector << '('
    collector = visit o.left, collector
    collector << " - "
    collector = visit o.right, collector
    collector << ')'
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
    collector = visit o.right, collector
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
    collector << "NVL("
    collector = visit o.left, collector
    collector << Arel::Visitors::Oracle::COMMA
    collector = visit Arel::Nodes.build_quoted(true), collector
    collector << ")"
    collector
  end

  def visit_ArelExtensions_Nodes_Rand o, collector
    collector << "dbms_random.value("
    if(o.left != nil && o.right != nil)
      collector << "'#{o.left}'"
      collector << Arel::Visitors::Oracle::COMMA
      collector << "'#{o.right}'"
    end
    collector << ")"
    collector
  end

  def visit_ArelExtensions_Nodes_Replace o, collector
    collector << "REPLACE("
    collector = visit o.expr,collector
    collector << Arel::Visitors::Oracle::COMMA
    collector = visit o.left, collector
    collector << Arel::Visitors::Oracle::COMMA
    collector = visit o.right, collector
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
      collector << 'TRIM("BOTH"'
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

    def visit_ArelExtensions_Nodes_Ltrim o , collector
      collector << 'TRIM("LEADING",'
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


    def visit_ArelExtensions_Nodes_Rtrim o , collector
      collector << 'TRIM("TRAILING",'
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

      def visit_ArelExtensions_InsertManager_BulkValues o, collector
        table = collector.value.sub(/\AINSERT INTO/, '')
        into = " INTO#{table}"
        collector = Arel::Collectors::SQLString.new
        collector << "INSERT ALL\n"
  #      row_nb = o.left.length
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