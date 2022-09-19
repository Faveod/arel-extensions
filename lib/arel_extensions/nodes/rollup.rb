# The following is a patch to activerecord when it doesn't
# have RollUp defined, i.e. for rails < 5.2

begin
  Arel::Nodes.const_get('RollUp')
rescue NameError => e
  module Arel
    module Nodes
      class RollUp < Arel::Nodes::Unary
      end
    end
  end

  module Arel
    module Visitors
      class PostgreSQL
        # Utilized by GroupingSet, Cube & RollUp visitors to
        # handle grouping aggregation semantics
        def grouping_array_or_grouping_element(o, collector)
          if o.expr.is_a? Array
            collector << "( "
            visit o.expr, collector
            collector << " )"
          else
            visit o.expr, collector
          end
        end

        def visit_Arel_Nodes_RollUp(o, collector)
          collector << "ROLLUP"
          grouping_array_or_grouping_element o, collector
        end
      end
    end
  end
end
