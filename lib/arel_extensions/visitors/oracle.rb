#require 'oracle_visitor'
module ArelExtensions
  module Visitors
    Arel::Visitors::Oracle.class_eval do

      SPECIAL_CHARS = {"\t" => 'CHR(9)', "\n" => 'CHR(10)', "\r" => 'CHR(13)'}
      Arel::Visitors::Oracle::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'IW', 'y' => 'YEAR', 'wd' => 'D', 'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'}
      Arel::Visitors::Oracle::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'IYYY', '%C' => 'CC', '%y' => 'YY', '%m' => 'MM', '%B' => 'Month', '%^B' => 'MONTH', '%b' => 'Mon', '%^b' => 'MON',
        '%d' => 'DD', '%e' => 'FMDD', '%j' => 'DDD', '%w' => '', '%A' => 'Day',                             # day, weekday
        '%H' => 'HH24', '%k' => '', '%I' => 'HH', '%l' => '', '%P' => 'am', '%p' => 'AM',                   # hours
        '%M' => 'MI', '%S' => 'SS', '%L' => 'MS', '%N' => 'US', '%z' => 'tz'                                # seconds, subseconds
      }
      Arel::Visitors::Oracle::NUMBER_COMMA_MAPPING = { 'en_US' => '.,', 'fr_FR' => ',', 'sv_SE' => ', ' }

      def visit_ArelExtensions_Nodes_Log10 o, collector
          collector << "LOG("
          o.expressions.each_with_index { |arg, i|
            collector << Arel::Visitors::ToSql::COMMA unless i == 0
            collector = visit arg, collector
          }
          collector << ",10)"
          collector
      end

      def visit_ArelExtensions_Nodes_Power o, collector
            collector << "POWER("
            o.expressions.each_with_index { |arg, i|
              collector << Arel::Visitors::ToSql::COMMA unless i == 0
              collector = visit arg, collector
            }
            collector << ")"
            collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << '('
        o.expressions.each_with_index { |arg, i|
          collector = visit o.convert_to_string_node(arg), collector
          collector << ' || ' unless i == o.expressions.length - 1
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IMatches o, collector
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
      if o.ai
        collector << "NLSSORT("
        collector = visit o.expressions.first, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector << "'NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC'"
        collector << ")"
      elsif o.ci
        collector << "NLSSORT("
        collector = visit o.expressions.first, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector << "'NLS_SORT = BINARY_CI NLS_COMP = LINGUISTIC'"
        collector << ")"
      else
        collector = visit o.expressions.first, collector
      end
        collector
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "(LISTAGG("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA
        if o.right  && o.right != 'NULL'
          collector = visit o.right, collector
        else
          collector = visit Arel::Nodes.build_quoted(','), collector
        end
        collector << ") WITHIN GROUP (ORDER BY "
        if !o.orders.blank?
          o.orders.each_with_index do |order,i|
            collector << Arel::Visitors::Oracle::COMMA unless i == 0
            collector = visit order, collector
          end
        else
          collector = visit o.left, collector
        end
        collector << "))"
        collector
      end

      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          if i > 0 && o.left_node_type == :text
            if arg == ''
              collector << 'empty_clob()'
            else
              collector << 'TO_CLOB('
              collector = visit arg, collector
              collector << ')'
            end
          else
            collector = visit arg, collector
          end
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_MD5 o, collector
        collector << "LOWER (RAWTOHEX (DBMS_OBFUSCATION_TOOLKIT.md5(input => UTL_I18N.STRING_TO_RAW("
        collector = visit o.left, collector
        collector << ", 'AL32UTF8'))))"
        collector
      end

      # :date is not possible in Oracle since this type does not really exist
      def visit_ArelExtensions_Nodes_DateDiff o, collector
        lc = o.left_node_type == :ruby_date || o.left_node_type == :ruby_time
        rc = o.right_node_type == :ruby_date || o.right_node_type == :ruby_time
        collector << '('
        collector << 'TO_DATE(' if lc
        collector = visit o.left, collector
        collector << ')' if lc
        collector << " - "
        collector << 'TO_DATE(' if rc
        collector = visit o.right, collector
        collector << ')' if rc
        collector << ')'
        if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
          collector << ' * (CASE WHEN (TRUNC('
          collector << 'TO_DATE(' if lc
          collector = visit o.left, collector
          collector << ')' if lc
          collector << Arel::Visitors::Oracle::COMMA
          collector << "'DDD') = "
          collector << 'TO_DATE(' if lc
          collector = visit o.left, collector
          collector << ')' if lc
          collector << ') THEN 1 ELSE 86400 END)' # converts to seconds
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        case o.left
        when 'wd', 'w'
          collector << "TO_CHAR("
          collector = visit o.right, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit Arel::Nodes.build_quoted(Arel::Visitors::Oracle::DATE_MAPPING[o.left]), collector
        else
          collector << "EXTRACT(#{Arel::Visitors::Oracle::DATE_MAPPING[o.left]} FROM "
          collector = visit o.right, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Cast o, collector
        case o.as_attr
        when :string
          as_attr = Arel::Nodes::SqlLiteral.new('varchar(255)')
        when :time
          left = Arel::Nodes::NamedFunction.new('TO_CHAR',[o.left,Arel::Nodes.build_quoted('HH24:MI:SS')])
          collector = visit left, collector
          return collector
        when :number
          as_attr = Arel::Nodes::SqlLiteral.new('int')
        when :datetime
          as_attr = Arel::Nodes::SqlLiteral.new('timestamp')
        when :binary
          as_attr = Arel::Nodes::SqlLiteral.new('binary')
        else
          as_attr = Arel::Nodes::SqlLiteral.new(o.as_attr.to_s)
        end
        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
        collector = visit as_attr, collector
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
        collector = visit o.left, collector
        collector << ' IS NULL'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNotNull o, collector
        collector = visit o.left, collector
        collector << ' IS NOT NULL'
        collector
      end

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << "DBMS_RANDOM.VALUE("
        if o.left && o.right
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector = visit o.right, collector
        end
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

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "INSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << "SUBSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::Oracle::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << 'TRIM(' # BOTH
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector << '(' if o.left.is_a? ArelExtensions::Nodes::Trim
        if o.type_of_attribute(o.left) == :text
          collector << 'dbms_lob.SUBSTR('
          collector = visit o.left, collector
          collector << Arel::Visitors::Oracle::COMMA
          collector << 'COALESCE(dbms_lob.GETLENGTH('
          collector = visit o.left, collector
          collector << "), 0)"
          collector << Arel::Visitors::Oracle::COMMA
          collector << '1)'
        else
          collector = visit o.left, collector
        end
        collector << ')' if o.left.is_a? ArelExtensions::Nodes::Trim
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << 'TRIM(LEADING '
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        collector << 'TRIM(TRAILING '
        if o.right.expr && SPECIAL_CHARS[o.right.expr]
          collector << SPECIAL_CHARS[o.right.expr]
        else
          collector = visit o.right, collector
        end
        collector << ' FROM '
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
        visit o.left.trim.length.coalesce(0).eq(0), collector
      end

      def visit_ArelExtensions_Nodes_NotBlank o, collector
        visit o.left.trim.length.coalesce(0).gt(0), collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << '('
        collector = visit o.left, collector
        collector << (o.right.value >= 0 ? ' + ' : ' - ')
        collector = visit o.oracle_value(o.right), collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        collector << "TO_CHAR("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA

        f = o.iso_format.gsub(/\ (\w+)/, ' "\1"')
        Arel::Visitors::Oracle::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
        collector = visit Arel::Nodes.build_quoted(f), collector

        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Repeat o, collector
        collector << "LPAD("
        collector = visit o.expressions[0], collector #can't put empty string, otherwise it wouldn't work
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.expressions[1], collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.expressions[0], collector
        collector << ")"
        collector
      end

        # add primary_key if not present, avoid zip
      if Arel::VERSION.to_i < 7
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          collector << "("
          o.left.each_with_index do |row, idx| # values
          collector << " UNION ALL " if idx != 0
            collector << "(SELECT "
            v = Arel::Nodes::Values.new(row, o.cols)
            len = v.expressions.length - 1
            v.expressions.each_with_index { |value, i|
                case value
                when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                  collector = visit value, collector
                else
                  attr = v.columns[i]
                  collector << quote(value, attr && column_for(attr)).to_s
                end
                collector << Arel::Visitors::Oracle::COMMA unless i == len
            }
            collector << ' FROM DUAL)'
          end
          collector << ")"
          collector
        end
      else
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          collector << "("
          o.left.each_with_index do |row, idx|
            collector << " UNION ALL " if idx != 0
            collector << "(SELECT "
            v = Arel::Nodes::Values.new(row, o.cols)
            len = v.expressions.length - 1
            v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
              case value
              when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                collector = visit value, collector
              else
                collector << (attr && attr.able_to_type_cast? ? quote(attr.type_cast_for_database(value)) : quote(value).to_s)
              end
              collector << Arel::Visitors::Oracle::COMMA unless i == len
            }
            collector << ' FROM DUAL)'
          end
          collector << ")"
          collector
        end
      end


      def get_time_converted element
        if element.is_a?(Time)
          ArelExtensions::Nodes::Format.new [element, '%H:%M:%S']
        elsif element.is_a?(Arel::Attributes::Attribute)
          col = Arel::Table.engine.connection.schema_cache.columns_hash(element.relation.table_name)[element.name.to_s]
          if col && (col.type == :time)
            ArelExtensions::Nodes::Format.new [element, '%H:%M:%S']
          else
            element
          end
        else
          element
        end
      end


      remove_method(:visit_Arel_Nodes_GreaterThanOrEqual) rescue nil
      def visit_Arel_Nodes_GreaterThanOrEqual o, collector
        collector = visit get_time_converted(o.left), collector
        collector << " >= "
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_GreaterThan) rescue nil
      def visit_Arel_Nodes_GreaterThan o, collector
        collector = visit get_time_converted(o.left), collector
        collector << " > "
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_LessThanOrEqual) rescue nil
      def visit_Arel_Nodes_LessThanOrEqual o, collector
        collector = visit get_time_converted(o.left), collector
        collector << " <= "
        collector = visit get_time_converted(o.right), collector
        collector
      end

      remove_method(:visit_Arel_Nodes_LessThan) rescue nil
      def visit_Arel_Nodes_LessThan o, collector
        collector = visit get_time_converted(o.left), collector
        collector << " < "
        collector = visit get_time_converted(o.right), collector
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

      alias_method :old_visit_Arel_Nodes_TableAlias, :visit_Arel_Nodes_TableAlias
      def visit_Arel_Nodes_TableAlias o, collector
        if o.name.length > 30
          o = Arel::Table.new(o.table_name).alias(Base64.urlsafe_encode64(Digest::MD5.new.digest(o.name)).tr('=', '').tr('-', '_'))
        end
        old_visit_Arel_Nodes_TableAlias(o,collector)
      end


      alias_method :old_visit_Arel_Attributes_Attribute, :visit_Arel_Attributes_Attribute
      def visit_Arel_Attributes_Attribute o, collector
        join_name = o.relation.table_alias || o.relation.name
        if join_name.length > 30
          join_name = Arel.shorten(join_name)
        end
        collector << "#{quote_table_name join_name}.#{quote_column_name o.name}"
      end


      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        col = o.left.coalesce(0)
        comma = Arel::Visitors::Oracle::NUMBER_COMMA_MAPPING[o.locale] || '.,'
        comma_in_format = o.precision == 0 ? '' : 'D'
        nines_after = (1..o.precision-1).map{'9'}.join('')+'0'
        if comma.length == 1
          options = Arel::Nodes.build_quoted("NLS_NUMERIC_CHARACTERS = '"+comma+" '")
          nines_before = ("999"*4+"990")
        else
          options = Arel::Nodes.build_quoted("NLS_NUMERIC_CHARACTERS = '"+comma+"'")
          nines_before = ("999G"*4+"990")
        end
        sign = ArelExtensions::Nodes::Case.new.when(col<0).
                  then('-').
                  else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
        sign_length = o.flags.include?('+') || o.flags.include?(' ') ?
                Arel::Nodes.build_quoted(1) :
                ArelExtensions::Nodes::Case.new.when(col<0).then(1).else(0)

        if o.scientific_notation
          number = Arel::Nodes::NamedFunction.new('TO_CHAR',[
                Arel::Nodes.build_quoted(col.abs),
                Arel::Nodes.build_quoted('FM'+nines_before+comma_in_format+nines_after+'EEEE'),
                options
              ])
          if o.type == 'e'
            number = number.replace('E','e')
          end
        else
          number = Arel::Nodes::NamedFunction.new('TO_CHAR',[
                Arel::Nodes.build_quoted(col.abs),
                Arel::Nodes.build_quoted('FM'+nines_before+comma_in_format+nines_after),
                options
              ])
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

      def visit_ArelExtensions_Nodes_Std o, collector
        collector << (o.unbiased_estimator ? "STDDEV_SAMP(" : "STDDEV_POP(")
        visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Variance o, collector
        collector << (o.unbiased_estimator ? "VAR_SAMP(" : "VAR_POP(")
        visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_LevenshteinDistance o, collector
        collector << "UTL_MATCH.edit_distance("
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Json o,collector
        case o.hash
        when Array
          collector << 'to_jsonb(array['
          o.hash.each.with_index do |v,i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector  = visit v, collector
          end
          collector << '])'
        when Hash
          collector << 'jsonb_build_object('
          o.hash.each.with_index do |(k,v),i|
            if i != 0
              collector << Arel::Visitors::MySQL::COMMA
            end
            collector = visit k, collector
            collector << Arel::Visitors::MySQL::COMMA
            collector = visit v, collector
          end
          collector << ')'
        when String,Numeric,TrueClass,FalseClass
          collector = visit Arel::Nodes.build_quoted("#{o.hash}"), collector
          collector << '::jsonb'
        when NilClass
          collector  << %Q['null'::jsonb]
        when Arel::Attributes::Attribute
          collector = visit o.hash.cast(:jsonb), collector
        else
          collector = visit o.hash.cast(:jsonb), collector
          collector << '::jsonb'
        end
        collector
      end

      def visit_ArelExtensions_Nodes_JsonMerge o,collector
        o.expressions.each.with_index do |v,i|
          if i != 0
            collector << ' || '
          end
          collector = visit v, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_JsonGet o,collector
        collector = visit o.hash, collector
        collector << ' -> '
        collector = visit o.key, collector
        collector
      end

      def visit_ArelExtensions_Nodes_JsonSet o,collector
        collector << 'jsonb_set('
        collector = visit o.hash, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector << 'array['
        collector = visit o.key, collector
        collector << ']'
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.value, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector << 'true)'
        collector
      end

    end
  end
end
