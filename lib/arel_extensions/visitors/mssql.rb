module ArelExtensions
  module Visitors
    module MSSQL

      MSSQL_CLASS_NAMES = %i[MSSQL SQLServer].freeze

      mssql_class =
        Arel::Visitors
          .constants
          .select { |c| Arel::Visitors.const_get(c).is_a?(Class)  }
          .find { |c| MSSQL_CLASS_NAMES.include?(c) }

      # This guard is necessary because:
      #
      # 1. const_get(mssql_class) will fail when mssql_class is nil.
      # 2. mssql_class could be nil under certain conditions:
      #   1. especially on ruby 2.5 (and surprisingly not jruby 9.2) and 3.0+.
      #   2. when not working with mssql itself.
      if mssql_class
        LOADED_VISITOR = Arel::Visitors.const_get(mssql_class)

        LOADED_VISITOR::DATE_MAPPING = {
          'd' => 'day', 'm' => 'month', 'y' => 'year',
          'wd' => 'weekday', 'w' => 'week',
          'h' => 'hour', 'mn' => 'minute', 's' => 'second'
        }.freeze

        LOADED_VISITOR::DATE_FORMAT_DIRECTIVES = {
          '%Y' => 'YYYY', '%C' => '', '%y' => 'YY', '%m' => 'MM', '%B' => 'month', '%^B' => '', '%b' => '', '%^b' => '', # year, month
          '%V' => 'iso_week', '%G' => '',                                                                                # ISO week number and year of week
          '%d' => 'DD', '%e' => ''  , '%j' => ''  , '%w' => 'dw', %'a' => '', '%A' => 'weekday',                         # day, weekday
          '%H' => 'hh', '%k' => ''  , '%I' => ''  , '%l' => ''  , '%P' => '', '%p' => '',                                # hours
          '%M' => 'mi', '%S' => 'ss', '%L' => 'ms', '%N' => 'ns', '%z' => 'tz'
        }.freeze

        LOADED_VISITOR::DATE_FORMAT_FORMAT = {
          'YY' => '0#', 'MM' => '0#', 'DD' => '0#',
          'hh' => '0#', 'mi' => '0#', 'ss' => '0#',
          'iso_week' => '0#'
        }

        LOADED_VISITOR::DATE_NAME = [
          '%B', '%A'
        ]

        LOADED_VISITOR::DATE_FORMAT_REGEX =
          Regexp.new(
            LOADED_VISITOR::DATE_FORMAT_DIRECTIVES
              .keys
              .map{|k| Regexp.escape(k)}
              .join('|')
          ).freeze

        # TODO; all others... http://www.sql-server-helper.com/tips/date-formats.aspx
        LOADED_VISITOR::DATE_CONVERT_FORMATS = {
          'YYYY-MM-DD' => 120,
          'YY-MM-DD' => 120,
          'MM/DD/YYYY' => 101,
          'MM-DD-YYYY' => 110,
          'YYYY/MM/DD' => 111,
          'DD-MM-YYYY' => 105,
          'DD-MM-YY'   => 5,
          'DD.MM.YYYY' => 104,
          'YYYY-MM-DDTHH:MM:SS:MMM' => 126
        }.freeze
      end

      # Quoting in JRuby + AR < 5 requires special handling for MSSQL.
      #
      # It relied on @connection.quote, which in turn relied on column type for
      # quoting. We need only to rely on the value type.
      #
      # It didn't handle numbers correctly: `quote(1, nil)` translated into
      # `N'1'` which we don't want.
      #
      # The following is adapted from
      # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/connection_adapters/abstract/quoting.rb
      #
      if RUBY_PLATFORM == 'java' && Arel::VERSION.to_i <= 6
        def quote_string(s)
          s.gsub('\\', '\&\&').gsub("'", "''") # ' (for ruby-mode)
        end

        def quoted_binary(value) # :nodoc:
          "'#{quote_string(value.to_s)}'"
        end

        def quoted_date(value)
          if value.acts_like?(:time)
            if (ActiveRecord.respond_to?(:default_timezone) && ActiveRecord.default_timezone == :utc) || ActiveRecord::Base.default_timezone == :utc
              value = value.getutc if value.respond_to?(:getutc) && !value.utc?
            else
              value = value.getlocal if value.respond_to?(:getlocal)
            end
          end
          # new versions of AR use `to_fs`, but we want max compatibility, and we're
          # not going to write it over and over, so it's fine like that.
          result = value.to_formatted_s(:db)
          if value.respond_to?(:usec) && value.usec > 0
            result << '.' << sprintf('%06d', value.usec)
          else
            result
          end
        end

        def quoted_true
          'TRUE'
        end

        def quoted_false
          'FALSE'
        end

        def quoted_time(value) # :nodoc:
          value = value.change(year: 2000, month: 1, day: 1)
          quoted_date(value).sub(/\A\d{4}-\d{2}-\d{2} /, "")
        end

        def quote value, column = nil
          case value
          when Arel::Nodes::SqlLiteral
            value
          when String, Symbol, ActiveSupport::Multibyte::Chars
            "'#{quote_string(value.to_s)}'"
          when true
            quoted_true
          when false
            quoted_false
          when nil
            'NULL'
          # BigDecimals need to be put in a non-normalized form and quoted.
          when BigDecimal
            value.to_s('F')
          when Numeric, ActiveSupport::Duration
            value.to_s
          when Arel::VERSION.to_i > 6 && ActiveRecord::Type::Time::Value
            "'#{quoted_time(value)}'"
          when Date, Time
            "'#{quoted_date(value)}'"
          when Class
            "'#{value}'"
          else
            raise TypeError, "can't quote #{value.class.name}"
          end
        end
      end

      alias_method(:old_primary_Key_From_Table, :primary_Key_From_Table) rescue nil
      def primary_Key_From_Table t
        return unless t

        column_name = @connection.schema_cache.primary_keys(t.name) ||
                      @connection.schema_cache.columns_hash(t.name).first.try(:second).try(:name)
        column_name ? t[column_name] : nil
      end

      # Math Functions
      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << 'CEILING('
        collector = visit o.expr, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Log10 o, collector
        collector << 'LOG10('
          o.expressions.each_with_index { |arg, i|
            collector << Arel::Visitors::ToSql::COMMA if i != 0
            collector = visit arg, collector
          }
          collector << ')'
          collector
      end

      def visit_ArelExtensions_Nodes_Power o, collector
        collector << 'POWER('
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << '('
        collector = visit o.expr, collector
        collector << ' IS NULL)'
        collector
      end

      def visit_ArelExtensions_Nodes_IsNotNull o, collector
        collector << '('
          collector = visit o.expr, collector
          collector << ' IS NOT NULL)'
          collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << 'CONCAT('
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Repeat o, collector
        collector << 'REPLICATE('
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end



      def visit_ArelExtensions_Nodes_DateDiff o, collector
        case o.right_node_type
        when :ruby_date, :ruby_time, :date, :datetime, :time
          collector << case o.left_node_type
                      when :ruby_time, :datetime, :time then 'DATEDIFF(second'
                      else                                   'DATEDIFF(day'
                      end
          collector << LOADED_VISITOR::COMMA
          collector = visit o.right, collector
          collector << LOADED_VISITOR::COMMA
          collector = visit o.left, collector
          collector << ')'
        else
          da = ArelExtensions::Nodes::DateAdd.new([])
          collector << 'DATEADD('
          collector = visit da.mssql_datepart(o.right), collector
          collector << LOADED_VISITOR::COMMA
          collector << '-('
          collector = visit da.mssql_value(o.right), collector
          collector << ')'
          collector << LOADED_VISITOR::COMMA
          collector = visit o.left, collector
          collector << ')'
          collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << 'DATEADD('
        collector = visit o.mssql_datepart(o.right), collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.mssql_value(o.right), collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.left, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        if o.with_interval && o.left.end_with?('i')
          collector = visit o.right, collector
        else
          left = o.left.end_with?('i') ? o.left[0..-2] : o.left
          conv = %w[h mn s].include?(o.left)
          collector << 'DATEPART('
          collector << LOADED_VISITOR::DATE_MAPPING[left]
          collector << LOADED_VISITOR::COMMA
          collector << 'CONVERT(datetime,' if conv
          collector = visit o.right, collector
          collector << ')' if conv
          collector << ')'
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Length o, collector
        if o.bytewise
          collector << '(DATALENGTH('
          collector = visit o.expr, collector
          collector << ') / ISNULL(NULLIF(DATALENGTH(LEFT(COALESCE('
          collector = visit o.expr, collector
          collector << ", '#' ), 1 )), 0), 1))"
          collector
        else
          collector << 'LEN('
          collector = visit o.expr, collector
          collector << ')'
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Round o, collector
        collector << 'ROUND('
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        if o.expressions.length == 1
          collector << LOADED_VISITOR::COMMA
          collector << '0'
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << 'CHARINDEX('
        collector = visit o.right, collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.left, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << 'SUBSTRING('
        collector = visit o.expressions[0], collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.expressions[1], collector
        collector << LOADED_VISITOR::COMMA
        collector = o.expressions[2] ? visit(o.expressions[2], collector) : visit(o.expressions[0].length, collector)
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        # NOTE: in MSSQL's `blank`, o.right is the space char so we need to
        # account for it.
        if o.right && !/\A\s\Z/.match(o.right.expr)
          collector << 'dbo.TrimChar('
          collector = visit o.left, collector
          collector << Arel::Visitors::MSSQL::COMMA
          collector = visit o.right, collector
          collector << ')'
        else
          collector << "LTRIM(RTRIM("
          collector = visit o.left, collector
          collector << "))"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        if o.right
          collector << 'REPLACE(REPLACE(LTRIM(REPLACE(REPLACE('
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << 'LTRIM('
          collector = visit o.left, collector
          collector << ')'
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        if o.right
          collector << 'REPLACE(REPLACE(RTRIM(REPLACE(REPLACE('
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << 'RTRIM('
          collector = visit o.left, collector
          collector << ')'
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
        visit o.expr.coalesce('').trim.length.eq(0), collector
      end

      def visit_ArelExtensions_Nodes_NotBlank o, collector
        visit o.expr.coalesce('').trim.length.gt(0), collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        visit_ArelExtensions_Nodes_FormattedDate o, collector
      end

      def visit_ArelExtensions_Nodes_FormattedDate o, collector
        f = ArelExtensions::Visitors::strftime_to_format(o.iso_format, LOADED_VISITOR::DATE_FORMAT_DIRECTIVES)
        if fmt = LOADED_VISITOR::DATE_CONVERT_FORMATS[f]
          collector << "CONVERT(VARCHAR(#{f.length})"
          collector << LOADED_VISITOR::COMMA
          if o.time_zone
            collector << 'CONVERT(datetime'
            collector << LOADED_VISITOR::COMMA
            collector << ' '
          end
          collector = visit o.left, collector
          case o.time_zone
          when Hash
            src_tz, dst_tz = o.time_zone.first
            collector << ') AT TIME ZONE '
            collector = visit Arel.quoted(src_tz), collector
            collector << ' AT TIME ZONE '
            collector = visit Arel.quoted(dst_tz), collector
          when String
            collector << ') AT TIME ZONE '
            collector = visit Arel.quoted(o.time_zone), collector
          end
          collector << LOADED_VISITOR::COMMA
          collector << fmt.to_s
          collector << ')'
          collector
        else
          s = StringScanner.new o.iso_format
          collector << '('
          sep = ''
          while !s.eos?
            collector << sep
            sep = ' + '
            case
            when s.scan(LOADED_VISITOR::DATE_FORMAT_REGEX)
              dir = LOADED_VISITOR::DATE_FORMAT_DIRECTIVES[s.matched]
              fmt = LOADED_VISITOR::DATE_FORMAT_FORMAT[dir]
              date_name = LOADED_VISITOR::DATE_NAME.include?(s.matched)
              collector << 'LTRIM(RTRIM('
              collector << 'FORMAT(' if fmt
              collector << 'STR('    if !fmt && !date_name
              collector << (date_name ? 'DATENAME(' : 'DATEPART(')
              collector << dir
              collector << LOADED_VISITOR::COMMA
              if o.time_zone
                collector << 'CONVERT(datetime'
                collector << LOADED_VISITOR::COMMA
                collector << ' '
              end
              collector = visit o.left, collector
              case o.time_zone
              when Hash
                src_tz, dst_tz = o.time_zone.first.first, o.time_zone.first.second
                collector << ') AT TIME ZONE '
                collector = visit Arel.quoted(src_tz), collector
                collector << ' AT TIME ZONE '
                collector = visit Arel.quoted(dst_tz), collector
              when String
                collector << ') AT TIME ZONE '
                collector = visit Arel.quoted(o.time_zone), collector
              end
              collector << ')'
              collector << ')'                                  if !fmt && !date_name
              collector << LOADED_VISITOR::COMMA << "'#{fmt}')" if fmt
              collector << '))'
            when s.scan(/^%%/)
              collector = visit Arel.quoted('%'), collector
            when s.scan(/[^%]+|./)
              collector = visit Arel.quoted(s.matched), collector
            end
          end
          collector << ')'
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << 'REPLACE('
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_FindInSet o, collector
        collector << 'dbo.FIND_IN_SET('
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ')'
        collector
      end

      # TODO; manage case insensitivity
      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = visit o.left.ci_collate, collector
        collector << ' LIKE '
        collector = visit o.right.ci_collate, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      # TODO; manage case insensitivity
      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector = visit o.left.ci_collate, collector
        collector << ' NOT LIKE '
        collector = visit o.right.ci_collate, collector
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
        collector = visit o.left.collate(true, true), collector
        collector << ' LIKE '
        collector = visit o.right.collate(true, true), collector
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

      def visit_ArelExtensions_Nodes_Collate o, collector
        if o.ai && o.ci
          collector = visit o.expressions.first, collector
          collector << ' COLLATE Latin1_General_CI_AI'
        elsif o.ai
          collector = visit o.expressions.first, collector
          collector << ' COLLATE Latin1_General_CS_AI'
        elsif o.ci
          collector = visit o.expressions.first, collector
          collector << ' COLLATE Latin1_General_CI_AS'
        else
          collector = visit o.expressions.first, collector
          collector << ' COLLATE Latin1_General_CS_AS'
        end
        collector
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
        collector << ' AS '
        # Sometimes these values are already quoted, if they are, don't double quote it
        lft, rgt =
          if o.right.is_a?(Arel::Nodes::SqlLiteral)
            if Arel::VERSION.to_i >= 6 && o.right[0] != '[' && o.right[-1] != ']'
              # This is a lie, it's not about arel version, but SQL Server's (>= 2000).
              ['[', ']']
            elsif o.right[0] != '"' && o.right[-1] != '"'
              ['"', '"']
            else
              []
            end
          end
        collector << lft if lft
        collector = visit o.right, collector
        collector << rgt if rgt
        collector
      end

      # SQL Server does not know about REGEXP
      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << "LIKE '%#{o.right}%'"
        collector
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << "NOT LIKE '%#{o.right}%'"
        collector
      end

      def visit_Arel_Nodes_RollUp(o, collector)
        collector << "ROLLUP"
        grouping_array_or_grouping_element o, collector
      end

      # TODO;
      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << '(STRING_AGG('
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector =
          if o.separator && o.separator != 'NULL'
            visit o.separator, collector
          else
            visit Arel.quoted(','), collector
          end
        collector << ') WITHIN GROUP (ORDER BY '
        if o.order.present?
          o.order.each_with_index do |order, i|
            collector << Arel::Visitors::Oracle::COMMA if i != 0
            collector = visit order, collector
          end
        else
          collector = visit o.left, collector
        end
        collector << '))'
        collector
      end

      def visit_ArelExtensions_Nodes_MD5 o, collector
        collector << "LOWER(CONVERT(NVARCHAR(32),HashBytes('MD5',CONVERT(VARCHAR,"
        collector = visit o.left, collector
        collector << ')),2))'
        collector
      end

      def visit_ArelExtensions_Nodes_Cast o, collector
        as_attr =
          case o.as_attr
          when :string
            'varchar'
          when :time
            'time'
          when :date
            'date'
          when :datetime
            'datetime'
          when :number, :decimal, :float
            'decimal(10,6)'
          when :int
            collector << 'CAST(CAST('
            collector = visit o.left, collector
            collector << ' AS decimal(10,0)) AS int)'
            return collector
          when :binary
            'binary'
          else
            o.as_attr.to_s
          end
        collector << 'CAST('
        collector = visit o.left, collector
        collector << ' AS '
        collector = visit Arel::Nodes::SqlLiteral.new(as_attr), collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        col = o.left.coalesce(0)
        locale = Arel.quoted(o.locale.tr('_', '-'))
        param = Arel.quoted("N#{o.precision}")
        sign = Arel.when(col < 0).
                  then('-').
                  else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
        sign_length = o.flags.include?('+') || o.flags.include?(' ') ?
              Arel.quoted(1) :
              Arel.when(col < 0).then(1).else(0)

        number =
          if o.scientific_notation
            ArelExtensions::Nodes::Concat.new([
                  Arel::Nodes::NamedFunction.new('FORMAT', [
                    col.abs / Arel.quoted(10).pow(col.abs.log10.floor),
                    param,
                    locale
                  ]),
                  o.type,
                  Arel::Nodes::NamedFunction.new('FORMAT', [
                    col.abs.log10.floor,
                    Arel.quoted('N0'),
                    locale
                  ])
                ])
          else
            Arel::Nodes::NamedFunction.new('FORMAT', [
                Arel.quoted(col.abs),
                param,
                locale
              ])
          end

        repeated_char =
          if o.width == 0
            Arel.quoted('')
          else
            Arel
              .when(Arel.quoted(o.width).abs - (number.length + sign_length) > 0)
              .then(Arel.quoted(
                      o.flags.include?('-') ? ' ' : (o.flags.include?('0') ? '0' : ' ')
                    ).repeat(Arel.quoted(o.width).abs - (number.length + sign_length))
                   )
              .else('')
          end
        before = !o.flags.include?('0') && !o.flags.include?('-') ? repeated_char : ''
        middle = o.flags.include?('0') && !o.flags.include?('-')  ? repeated_char : ''
        after  = o.flags.include?('-') ? repeated_char : ''
        full_number =
          ArelExtensions::Nodes::Concat.new([
            before,
            sign,
            middle,
            number,
            after
          ])
        collector = visit ArelExtensions::Nodes::Concat.new([Arel.quoted(o.prefix), full_number, Arel.quoted(o.suffix)]), collector
        collector
      end

      def visit_ArelExtensions_Nodes_Std o, collector
        collector << (o.unbiased_estimator ? 'STDEV(' : 'STDEVP(')
        visit o.left, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Variance o, collector
        collector << (o.unbiased_estimator ? 'VAR(' : 'VARP(')
        visit o.left, collector
        collector << ')'
        collector
      end


      def visit_ArelExtensions_Nodes_LevenshteinDistance o, collector
        collector << 'dbo.LEVENSHTEIN_DISTANCE('
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end


      def visit_ArelExtensions_Nodes_JsonGet o, collector
        collector << 'JSON_VALUE('
        collector = visit o.dict, collector
        collector << Arel::Visitors::MySQL::COMMA
        if o.key.is_a?(Integer)
          collector << "\"$[#{o.key}]\""
        else
          collector = visit Arel.quoted('$.') + o.key, collector
        end
        collector << ')'
        collector
      end

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
    end
  end
end
