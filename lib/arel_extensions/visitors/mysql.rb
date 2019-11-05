module ArelExtensions
  module Visitors
    Arel::Visitors::MySQL.class_eval do
      Arel::Visitors::MySQL::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'WEEK', 'y' => 'YEAR', 'wd' => 'WEEKDAY', 'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'}
      Arel::Visitors::MySQL::DATE_FORMAT_DIRECTIVES = { # ISO C / POSIX
        '%Y' => '%Y', '%C' =>   '', '%y' => '%y', '%m' => '%m', '%B' => '%M', '%b' => '%b', '%^b' => '%b',  # year, month
        '%d' => '%d', '%e' => '%e', '%j' => '%j', '%w' => '%w', '%A' => '%W',                               # day, weekday
        '%H' => '%H', '%k' => '%k', '%I' => '%I', '%l' => '%l', '%P' => '%p', '%p' => '%p',                 # hours
        '%M' => '%i', '%S' => '%S', '%L' =>   '', '%N' => '%f', '%z' => ''
      }


      #Math functions
      def visit_ArelExtensions_Nodes_Log10 o, collector
          collector << "LOG10("
          o.expressions.each_with_index { |arg, i|
            collector << Arel::Visitors::ToSql::COMMA unless i == 0
            collector = visit arg, collector
          }
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Power o, collector
        collector << "POW("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      #String functions
      def visit_ArelExtensions_Nodes_IMatches o, collector # insensitive on ASCII
        collector << 'LOWER('
        collector = visit o.left, collector
        collector << ') LIKE LOWER('
        collector = visit o.right, collector
        collector << ')'
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

      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector << 'LOWER('
        collector = visit o.left, collector
        collector << ') NOT LIKE LOWER('
        collector = visit o.right, collector
        collector << ')'
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Collate o, collector
        case o.expressions.first
        when Arel::Attributes::Attribute
          charset = case o.option
            when 'latin1','utf8'
              o.option
            else
              Arel::Table.engine.connection.charset || 'utf8'
            end
        else
          charset = (o.option == 'latin1') ? 'latin1' : 'utf8'
        end
        collector = visit o.expressions.first, collector
        if o.ai
          collector << " COLLATE #{charset == 'latin1' ? 'latin1_general_ci' : 'utf8_unicode_ci' }"
          #doesn't work in latin1
        elsif o.ci
          collector << " COLLATE #{charset == 'latin1' ? 'latin1_general_ci' : 'utf8_unicode_ci' }"
        else
          collector << " COLLATE #{charset}_bin"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::MySQL::COMMA unless i == 0
          if (arg.is_a?(Numeric)) || (arg.is_a?(Arel::Attributes::Attribute))
            collector << "CAST("
            collector = visit arg, collector
            collector << " AS char)"
          else
            collector = visit arg, collector
          end
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "GROUP_CONCAT("
        collector = visit o.left, collector
        if !o.order.blank?
          collector << ' ORDER BY '
          o.order.each_with_index do |order,i|
            collector << Arel::Visitors::ToSql::COMMA unless i == 0
            collector = visit order, collector
          end
        end
        if o.separator && o.separator != 'NULL'
          collector << ' SEPARATOR '
          collector = visit o.separator, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
          collector << 'TRIM(' # BOTH
          collector = visit o.right, collector
          collector << " FROM "
          collector = visit o.left, collector
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o , collector
          collector << 'TRIM(LEADING '
          collector = visit o.right, collector
          collector << " FROM "
          collector = visit o.left, collector
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o , collector
        collector << 'TRIM(TRAILING '
        collector = visit o.right, collector
        collector << " FROM "
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Repeat o, collector
        collector << "REPEAT("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime
          collector << "DATE_FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::MySQL::COMMA
          f = o.iso_format.dup
          Arel::Visitors::MySQL::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
          collector = visit Arel::Nodes.build_quoted(f), collector
          collector << ")"
        when :integer, :float, :decimal
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::ToSql::COMMA
          collector << '2'
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.right, collector
          collector << ")"
        else
          collector = visit o.left, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        if o.right_node_type == :ruby_date || o.right_node_type == :ruby_time || o.right_node_type == :date || o.right_node_type == :datetime || o.right_node_type == :time
          collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                        'TIMESTAMPDIFF(SECOND, '
                      else
                        'DATEDIFF('
                      end
          collector = visit o.right, collector
          collector << Arel::Visitors::MySQL::COMMA
          collector = visit o.left, collector
          collector << ")"
        else
          collector << '('
          collector = visit o.left, collector
          collector << ' - '
          if o.right.is_a?(ArelExtensions::Nodes::Duration)
            o.right.with_interval = true
            collector = visit o.right, collector
          else
            collector << '('
            collector = visit o.right, collector
            collector << ')'
          end
          collector << ')'
          collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATE_ADD("
        collector = visit o.left, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.mysql_value(o.right), collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_Duration o, collector
        if o.left == 'wd'
          collector << "(WEEKDAY("
          collector = visit o.right, collector
          collector << ") + 1) % 7"
        else
          if o.with_interval
            case o.left
            when  'd','m','y'
              interval = 'DAY'
            when 'h','mn','s'
              interval = 'SECOND'
            when /i\z/
              interval = Arel::Visitors::MySQL::DATE_MAPPING[o.left[0..-2]]
            else
              interval = nil
            end
          end
          collector << " INTERVAL " if o.with_interval && interval
          collector << "#{Arel::Visitors::MySQL::DATE_MAPPING[o.left]}("
          collector = visit o.right, collector
          collector << ")"
          collector << " #{interval} " if o.with_interval && interval
        end
        collector
      end


      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "ISNULL("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_IsNotNull o, collector
          collector << "NOT ISNULL("
          collector = visit o.expr, collector
          collector << ")"
          collector
      end

      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "(WEEKDAY("
        collector = visit o.date, collector
        collector << ") + 1) % 7"
        collector
      end

      def visit_ArelExtensions_Nodes_Cast o, collector
        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
        case o.as_attr
        when :string
          as_attr = Arel::Nodes::SqlLiteral.new('char')
        when :time
          as_attr = Arel::Nodes::SqlLiteral.new('time')
        when :int
          as_attr = Arel::Nodes::SqlLiteral.new('signed')
        when :number, :decimal
          as_attr = Arel::Nodes::SqlLiteral.new('decimal(20,6)')
        when :datetime
          as_attr = Arel::Nodes::SqlLiteral.new('datetime')
        when :date
          as_attr = Arel::Nodes::SqlLiteral.new('date')
        when :binary
          as_attr = Arel::Nodes::SqlLiteral.new('binary')
        else
          as_attr = Arel::Nodes::SqlLiteral.new(o.as_attr.to_s)
        end
        collector = visit as_attr, collector
        collector << ")"
        collector
      end

      alias_method :old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement
      def visit_Arel_Nodes_SelectStatement o, collector
        if !(collector.value.blank? || (collector.value.is_a?(Array) && collector.value[0].blank?)) && o.limit.blank? && o.offset.blank?
          o = o.dup
          o.orders = []
        end
        old_visit_Arel_Nodes_SelectStatement(o,collector)
      end

      alias_method :old_visit_Arel_Nodes_As, :visit_Arel_Nodes_As
      def visit_Arel_Nodes_As o, collector
        if o.left.is_a?(Arel::Nodes::Binary)
          collector << '('
          collector = visit o.left, collector
          collector << ')'
        else
          collector = visit o.left, collector
        end
        collector << " AS `"
        collector = visit o.right, collector
        collector << "`"
        collector
      end

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        col = o.left.coalesce(0)
        params = o.locale ? [o.precision,Arel::Nodes.build_quoted(o.locale)] : [o.precision]
        sign = ArelExtensions::Nodes::Case.new.when(col<0).
                  then('-').
                  else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
        sign_length = ArelExtensions::Nodes::Length.new([sign])

        if o.scientific_notation
          number = ArelExtensions::Nodes::Concat.new([
                  Arel::Nodes::NamedFunction.new('FORMAT',[
                    col.abs/Arel::Nodes.build_quoted(10).pow(col.abs.log10.floor)
                  ]+params),
                  o.type,
                  Arel::Nodes::NamedFunction.new('FORMAT',[
                    col.abs.log10.floor,
                    0
                  ])
                ])
        else
          number = Arel::Nodes::NamedFunction.new('FORMAT',[col.abs]+params)
        end

        repeated_char = (o.width == 0) ? Arel::Nodes.build_quoted('') : ArelExtensions::Nodes::Case.new().
          when(Arel::Nodes.build_quoted(o.width).abs-(number.length+sign_length)>0).
          then(Arel::Nodes.build_quoted(
              o.flags.include?('-') ? ' ' : (o.flags.include?('0') ? '0' : ' ')
            ).repeat(Arel::Nodes.build_quoted(o.width).abs-(number.length+sign_length))
          ).
          else('')
        before = (!o.flags.include?('0'))&&(!o.flags.include?('-')) ? repeated_char : ''
        middle = (o.flags.include?('0'))&&(!o.flags.include?('-'))  ? repeated_char : ''
        after  = o.flags.include?('-') ? repeated_char : ''
        full_number = ArelExtensions::Nodes::Concat.new([
            before,
            sign,
            middle,
            number,
            after
          ])
        collector = visit ArelExtensions::Nodes::Concat.new([Arel::Nodes.build_quoted(o.prefix),full_number,Arel::Nodes.build_quoted(o.suffix)]), collector
        collector
      end

      def visit_Aggregate_For_AggregateFunction o, collector
        if !(Arel::Table.engine.connection.send(:version) >= (Arel::Table.engine.connection.send(:mariadb?) ? '10.2.3' : '8.0'))
            warn("Warning : ArelExtensions: Window Functions are not available in the current version on the DBMS.")
            return collector
        end

        if o.order || o.group
          collector << " OVER ("
          if o.group
            collector << " PARTITION BY ("
            visit o.group, collector
            collector << ")"
          end
          if o.order
            collector << " ORDER BY ("
            visit o.order, collector
            collector << ")"
          end
          collector << ")"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Std o, collector
        collector << (o.unbiased_estimator ? "STDDEV_SAMP(" : "STDDEV_POP(")
        visit o.left, collector
        collector << ")"
        visit_Aggregate_For_AggregateFunction o, collector
        collector
      end

      def visit_ArelExtensions_Nodes_Variance o, collector
        collector << (o.unbiased_estimator ? "VAR_SAMP(" : "VAR_POP(")
        visit o.left, collector
        collector << ")"
        collector
      end

      # JSON if implemented only after 10.2.3 in MariaDb and 5.7 in MySql
      def json_supported?
        Arel::Table.engine.connection.send(:mariadb?) &&
        Arel::Table.engine.connection.send(:version) >= '10.2.3' ||
        !Arel::Table.engine.connection.send(:mariadb?) &&
        Arel::Table.engine.connection.send(:version) >= '5.7.0'
      end

      def visit_ArelExtensions_Nodes_Json o,collector
        return super if !json_supported?
        case o.dict
        when Array
          collector << 'JSON_ARRAY('
          o.dict.each.with_index do |v,i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector = visit v, collector
          end
          collector << ')'
        when Hash
          collector << 'JSON_OBJECT('
          o.dict.each.with_index do |(k,v),i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector = visit k, collector
            collector << Arel::Visitors::MySQL::COMMA
            collector = visit v, collector
          end
          collector << ')'
        else
          collector = visit o.dict, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_JsonMerge o,collector
        collector << 'JSON_MERGE_PATCH('
        o.expressions.each.with_index do |v,i|
          if i != 0
            collector << Arel::Visitors::MySQL::COMMA
          end
          collector = visit v, collector
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_JsonGet o,collector
        collector << 'JSON_EXTRACT('
        collector = visit o.dict, collector
        collector << Arel::Visitors::MySQL::COMMA
        if o.key.is_a?(Integer)
          collector << "\"$[#{o.key}]\""
        else
          collector = visit Arel::Nodes.build_quoted('$.')+o.key, collector
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_JsonSet o,collector
        collector << 'JSON_SET('
        collector = visit o.dict, collector
        collector << Arel::Visitors::MySQL::COMMA
        if o.key.is_a?(Integer)
          collector << "\"$[#{o.key}]\""
        else
          collector = visit Arel::Nodes.build_quoted('$.')+o.key, collector
        end
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.value, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_JsonGroup o, collector
        return super if !json_supported?
        if o.as_array
          collector << 'JSON_ARRAYAGG('
          collector = visit o.dict, collector
          collector << ')'
        else
          case o.dict
          when Hash
            collector << 'JSON_MERGE_PATCH(' if o.dict.length > 1
            o.dict.each.with_index do |(k,v),i|
              if i != 0
                collector << Arel::Visitors::MySQL::COMMA
              end
              collector << 'JSON_OBJECTAGG('
              collector = visit k, collector
              collector << Arel::Visitors::MySQL::COMMA
              collector = visit v, collector
              collector << ')'
            end
            collector << ')' if o.dict.length > 1
          else
            collector << 'JSON_OBJECTAGG('
            collector = visit o.dict, collector
            collector << ')'
          end
        end
        collector
      end

    end
  end
end
