module ArelExtensions
  module Visitors
    Arel::Visitors.send(:remove_const,'Oracle12') if Arel::Visitors.const_defined?('Oracle12')
    Arel::Visitors.const_set('Oracle12',Class.new(Arel::Visitors::Oracle)).class_eval do
      def visit_Arel_Nodes_SelectStatement(o, collector)
        # Oracle does not allow LIMIT clause with select for update
        if o.limit && o.lock
          raise ArgumentError, <<-MSG
          'Combination of limit and lock is not supported.
          because generated SQL statements
          `SELECT FOR UPDATE and FETCH FIRST n ROWS` generates ORA-02014.`
          MSG
        end

        super
      end

      def visit_Arel_Nodes_SelectOptions(o, collector)
        collector = maybe_visit o.offset, collector
        collector = maybe_visit o.limit, collector
        maybe_visit o.lock, collector
      end

      def visit_Arel_Nodes_Limit(o, collector)
        collector << "FETCH FIRST "
        collector = visit o.expr, collector
        collector << " ROWS ONLY"
      end

      def visit_Arel_Nodes_Offset(o, collector)
        collector << "OFFSET "
        visit o.expr, collector
        collector << " ROWS"
      end

      def visit_Arel_Nodes_Except(o, collector)
        collector << "( "
        collector = infix_value o, collector, " MINUS "
        collector << " )"
      end

      def visit_Arel_Nodes_UpdateStatement(o, collector)
        # Oracle does not allow ORDER BY/LIMIT in UPDATEs.
        if o.orders.any? && o.limit.nil?
          # However, there is no harm in silently eating the ORDER BY clause if no LIMIT has been provided,
          # otherwise let the user deal with the error
          o = o.dup
          o.orders = []
        end
        super
      end

      def visit_Arel_Nodes_BindParam(o, collector)
        collector.add_bind(o.value) { |i| ":a#{i}" }
      end

      def is_distinct_from(o, collector)
        collector << "DECODE("
        collector = visit [o.left, o.right, 0, 1], collector
        collector << ")"
      end

      def visit_ArelExtensions_Nodes_Json o,collector
        case o.dict
        when Array
          collector << 'json_array('
          o.dict.each.with_index do |v,i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector = visit v, collector
          end
          collector << ')'
        when Hash
          collector << 'json__object('
          o.dict.each.with_index do |(k,v),i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector << 'KEY '
            collector = visit k, collector
            collector << ' IS '
            collector = visit v, collector
            collector << 'FORMAT JSON'
          end
          collector << ')'
        when String, Numeric, TrueClass, FalseClass
          collector = visit Arel::Nodes.build_quoted("#{o.dict}"), collector
          collector << ' FORMAT JSON'
        when NilClass
          collector  << %Q['null' FORMAT JSON]
        when Arel::Attributes::Attribute
          collector = visit o.dict.cast('JSON'), collector
        else
          collector = visit o.dict, collector
          collector << ' FORMAT JSON'
        end
        collector
      end
    end
  end
end
