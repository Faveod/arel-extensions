module ArelExtensions
  module Visitors
    class Arel::Visitors::MySQL
      DATE_MAPPING = {
        'd' => 'DAY', 'm' => 'MONTH', 'w' => 'WEEK', 'y' => 'YEAR', 'wd' => 'WEEKDAY',
        'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'
      }.freeze

      DATE_FORMAT_DIRECTIVES = { # ISO C / POSIX
        '%Y' => '%Y', '%C' =>   '', '%y' => '%y', '%m' => '%m', '%B' => '%M', '%b' => '%b', '%^b' => '%b',  # year, month
        '%V' => '%v', '%G' => '%x',                                                                         # ISO week number and year of week
        '%d' => '%d', '%e' => '%e', '%j' => '%j', '%w' => '%w', '%A' => '%W',                               # day, weekday
        '%H' => '%H', '%k' => '%k', '%I' => '%I', '%l' => '%l', '%P' => '%p', '%p' => '%p',                 # hours
        '%M' => '%i', '%S' => '%S', '%L' =>   '', '%N' => '%f', '%z' => ''
      }.freeze


      # Math functions
      def visit_ArelExtensions_Nodes_Log10 o, collector
        collector << "LOG10("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Power o, collector
        collector << "POW("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      # String functions
      def visit_ArelExtensions_Nodes_IMatches o, collector # insensitive on ASCII
        collector << 'LOWER('
        collector = visit o.left, collector
        collector << ') LIKE LOWER('
        collector = visit o.right, collector
        collector << ')'
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_AiMatches o, collector
        collector = visit o.left.ai_collate, collector
        collector << ' LIKE '
        collector = visit o.right.ai_collate, collector
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_AiIMatches o, collector
        collector = visit o.left.ai_collate, collector
        collector << ' LIKE '
        collector = visit o.right.ai_collate, collector
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_SMatches o, collector
        collector = visit o.left.collate, collector
        collector << ' LIKE '
        collector = visit o.right.collate, collector
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector << 'LOWER('
        collector = visit o.left, collector
        collector << ') NOT LIKE LOWER('
        collector = visit o.right, collector
        collector << ')'
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Collate o, collector
        charset =
          case o.expressions.first
          when Arel::Attributes::Attribute
            case o.option
            when 'latin1','utf8'
              o.option
            else
              Arel::Table.engine.connection.charset || 'utf8'
            end
          else
            (o.option == 'latin1') ? 'latin1' : 'utf8'
          end
        collector = visit o.expressions.first, collector
        collector <<
          if o.ai
            " COLLATE #{charset == 'latin1' ? 'latin1_general_ci' : 'utf8_unicode_ci'}"
          # doesn't work in latin1
          elsif o.ci
            " COLLATE #{charset == 'latin1' ? 'latin1_general_ci' : 'utf8_unicode_ci'}"
          else
            " COLLATE #{charset}_bin"
          end
        collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
        o.expressions.each_with_index { |arg, i|
          collector << COMMA if i != 0
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
            collector << Arel::Visitors::ToSql::COMMA if i != 0
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

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << 'TRIM(LEADING '
        collector = visit o.right, collector
        collector << " FROM "
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
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
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_RegexpReplace o, collector
        if !regexp_replace_supported?
          warn("Warning : ArelExtensions: REGEXP_REPLACE does not seem to be available in the current version of the DBMS, it might crash")
        end
        super(o,collector)
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime, :time
          fmt = ArelExtensions::Visitors::strftime_to_format(o.iso_format, DATE_FORMAT_DIRECTIVES)
          collector << "DATE_FORMAT("
          collector << "CONVERT_TZ(" if o.time_zone
          collector = visit o.left, collector
          case o.time_zone
          when Hash
            src_tz, dst_tz = o.time_zone.first
            collector << COMMA
            collector = visit Arel.quoted(src_tz), collector
            collector << COMMA
            collector = visit Arel.quoted(dst_tz), collector
            collector << ')'
          when String
            collector << COMMA << "'UTC'" << COMMA
            collector = visit Arel.quoted(o.time_zone), collector
            collector << ')'
          end
          collector << COMMA
          collector = visit Arel.quoted(fmt), collector
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
        case o.right_node_type
        when :ruby_date, :ruby_time, :date, :datetime, :time
          collector <<
            case o.left_node_type
            when :ruby_time, :datetime, :time then 'TIMESTAMPDIFF(SECOND, '
            else                                   'DATEDIFF('
            end
          collector = visit o.right, collector
          collector << COMMA
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
        collector << COMMA
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
            interval =
              case o.left
              when 'd','m','y'
                'DAY'
              when 'h','mn','s'
                'SECOND'
              when /i\z/
                DATE_MAPPING[o.left[0..-2]]
              end
          end
          collector << " INTERVAL " if o.with_interval && interval
          collector << "#{DATE_MAPPING[o.left]}("
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
        as_attr =
          case o.as_attr
          when :binary           then 'binary'
          when :date             then 'date'
          when :datetime         then 'datetime'
          when :int              then 'signed'
          when :number, :decimal then 'decimal(20,6)'
          when :string           then 'char'
          when :time             then 'time'
          else                        o.as_attr.to_s
          end

        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
        collector = visit Arel::Nodes::SqlLiteral.new(as_attr), collector
        collector << ")"
        collector
      end

      alias_method(:old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement) rescue nil
      def visit_Arel_Nodes_SelectStatement o, collector
        if !(collector.value.blank? || (collector.value.is_a?(Array) && collector.value[0].blank?)) && o.limit.blank? && o.offset.blank?
          o = o.dup
          o.orders = []
        end
        old_visit_Arel_Nodes_SelectStatement(o,collector)
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
        collector << " AS "

        # sometimes these values are already quoted, if they are, don't double quote it
        quote = o.right.is_a?(Arel::Nodes::SqlLiteral) && o.right[0] != '`' && o.right[-1] != '`'

        collector << '`' if quote
        collector = visit o.right, collector
        collector << '`' if quote

        collector
      end

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        col = o.left.coalesce(0)
        params = o.locale ? [o.precision,Arel.quoted(o.locale)] : [o.precision]
        sign = Arel.when(col<0).
                  then('-').
                  else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
        sign_length = ArelExtensions::Nodes::Length.new([sign])

        number =
          if o.scientific_notation
            ArelExtensions::Nodes::Concat.new([
                    Arel::Nodes::NamedFunction.new('FORMAT',[
                      col.abs/Arel.quoted(10).pow(col.abs.log10.floor)
                    ]+params),
                    o.type,
                    Arel::Nodes::NamedFunction.new('FORMAT',[
                      col.abs.log10.floor,
                      0
                    ])
                  ])
          else
            Arel::Nodes::NamedFunction.new('FORMAT',[col.abs]+params)
          end

        repeated_char = (o.width == 0) ? Arel.quoted('') : ArelExtensions::Nodes::Case.new().
          when(Arel.quoted(o.width).abs-(number.length+sign_length)>0).
          then(Arel.quoted(
              o.flags.include?('-') ? ' ' : (o.flags.include?('0') ? '0' : ' ')
            ).repeat(Arel.quoted(o.width).abs-(number.length+sign_length))
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
        collector = visit ArelExtensions::Nodes::Concat.new([Arel.quoted(o.prefix),full_number,Arel.quoted(o.suffix)]), collector
        collector
      end

      def visit_Aggregate_For_AggregateFunction o, collector
        if !window_supported?
            warn("Warning : ArelExtensions: Window Functions are not available in the current version of the DBMS.")
            return collector
        end

        if !o.order.empty? || !o.group.empty?
          collector << " OVER ("
          if !o.group.empty?
            collector << " PARTITION BY ("
            visit o.group, collector
            collector << ")"
          end
          if !o.order.empty?
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
        visit_Aggregate_For_AggregateFunction o, collector
        collector
      end

      # JSON if implemented only after 10.2.3 (aggregations after 10.5.0) in MariaDb and 5.7 (aggregations after 5.7.22) in MySql
      def json_supported?
        version_supported?('10.5.0', '5.7.22')
      end

      def window_supported?
        version_supported?('10.2.3', '8.0')
      end

      def regexp_replace_supported?
        version_supported?('10.0.5', '8.0')
      end

      def version_supported?(mariadb_v = '10.2.3', mysql_v = '5.7.0')
        conn = Arel::Table.engine.connection
        conn.send(:mariadb?) && \
          (conn.respond_to?(:get_database_version) && conn.send(:get_database_version) >= mariadb_v || \
          conn.respond_to?(:version) && conn.send(:version) >= mariadb_v || \
          conn.instance_variable_get(:"@version") && conn.instance_variable_get(:"@version") >= mariadb_v) || \
          !conn.send(:mariadb?) && \
            (conn.respond_to?(:get_database_version) && conn.send(:get_database_version) >= mysql_v || \
            conn.respond_to?(:version) && conn.send(:version) >= mysql_v || \
            conn.instance_variable_get(:"@version") && conn.instance_variable_get(:"@version") >= mysql_v)
        # ideally we should parse the instance_variable @full_version because @version contains only the supposedly
        # corresponding mysql version of the current mariadb version (which is not very helpful most of the time)
      end

      def visit_ArelExtensions_Nodes_Json o,collector
        return super if !json_supported?

        case o.dict
        when Array
          collector << 'JSON_ARRAY('
          o.dict.each.with_index do |v,i|
            if i != 0
              collector << COMMA
            end
            collector = visit v, collector
          end
          collector << ')'
        when Hash
          collector << 'JSON_OBJECT('
          o.dict.each.with_index do |(k,v),i|
            if i != 0
              collector << COMMA
            end
            collector = visit k, collector
            collector << COMMA
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
            collector << COMMA
          end
          collector = visit v, collector
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_JsonGet o,collector
        collector << 'JSON_EXTRACT('
        collector = visit o.dict, collector
        collector << COMMA
        if o.key.is_a?(Integer)
          collector << "\"$[#{o.key}]\""
        else
          collector = visit Arel.quoted('$.')+o.key, collector
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_JsonSet o,collector
        collector << 'JSON_SET('
        collector = visit o.dict, collector
        collector << COMMA
        if o.key.is_a?(Integer)
          collector << "\"$[#{o.key}]\""
        else
          collector = visit Arel.quoted('$.')+o.key, collector
        end
        collector << COMMA
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
                collector << COMMA
              end
              collector << 'JSON_OBJECTAGG('
              collector = visit k, collector
              collector << COMMA
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
