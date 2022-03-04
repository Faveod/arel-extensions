module ArelExtensions
  module Visitors
    module MSSQL

      mssql_class = Arel::Visitors.constants.select { |c|
        Arel::Visitors.const_get(c).is_a?(Class) && %i[MSSQL SQLServer].include?(c)
      }.first

      LOADED_VISITOR = Arel::Visitors.const_get(mssql_class) || Arel::Visitors.const_get('MSSQL')

      LOADED_VISITOR::DATE_MAPPING = {
        'd' => 'day', 'm' => 'month', 'y' => 'year', 'wd' => 'weekday', 'w' => 'week', 'h' => 'hour', 'mn' => 'minute', 's' => 'second'
      }.freeze

      LOADED_VISITOR::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'YYYY', '%C' => '', '%y' => 'YY', '%m' => 'MM', '%B' =>   '', '%b' => '', '%^b' => '', # year, month
        '%d' => 'DD', '%e' => '', '%j' =>   '', '%w' => 'dw', '%A' => '', # day, weekday
        '%H' => 'hh', '%k' => '', '%I' =>   '', '%l' =>   '', '%P' => '', '%p' => '', # hours
        '%M' => 'mi', '%S' => 'ss', '%L' => 'ms', '%N' => 'ns', '%z' => 'tz'
      }.freeze

      LOADED_VISITOR::DATE_FORMAT_FORMAT = {
        'YY' => '0#', 'MM' => '0#', 'DD' => '0#', 'hh' => '0#', 'mi' => '0#', 'ss' => '0#'
      }

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
        'YY-MM-DD'  => 120,
        'MM/DD/YYYY' => 101,
        'MM-DD-YYYY' => 110,
        'YYYY/MM/DD' => 111,
        'DD-MM-YYYY' => 105,
        'DD-MM-YY'   => 5,
        'DD.MM.YYYY' => 104,
        'YYYY-MM-DDTHH:MM:SS:MMM' => 126
      }.freeze

      # Math Functions
      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << "CEILING("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

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
        collector << "POWER("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "("
        collector = visit o.expr, collector
        collector << " IS NULL)"
        collector
      end

      def visit_ArelExtensions_Nodes_IsNotNull o, collector
          collector << "("
          collector = visit o.expr, collector
          collector << " IS NOT NULL)"
          collector
      end

      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Repeat o, collector
        collector << "REPLICATE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
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
          collector << "DATEADD("
          collector = visit da.mssql_datepart(o.right), collector
          collector << LOADED_VISITOR::COMMA
          collector << "-("
          collector = visit da.mssql_value(o.right), collector
          collector << ")"
          collector << LOADED_VISITOR::COMMA
          collector = visit o.left, collector
          collector << ")"
          collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATEADD("
        collector = visit o.mssql_datepart(o.right), collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.mssql_value(o.right), collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        if o.with_interval && o.left.end_with?('i')
          collector = visit o.right, collector
        else
          left = o.left.end_with?('i') ? o.left[0..-2] : o.left
          conv = ['h', 'mn', 's'].include?(o.left)
          collector << 'DATEPART('
          collector << LOADED_VISITOR::DATE_MAPPING[left]
          collector << LOADED_VISITOR::COMMA
          collector << 'CONVERT(datetime,' if conv
          collector = visit o.right, collector
          collector << ')' if conv
          collector << ")"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Length o, collector
        if o.bytewise
          collector << "(DATALENGTH("
          collector = visit o.expr, collector
          collector << ") / ISNULL(NULLIF(DATALENGTH(LEFT(COALESCE("
          collector = visit o.expr, collector
          collector << ", '#' ), 1 )), 0), 1))"
          collector
        else
          collector << "LEN("
          collector = visit o.expr, collector
          collector << ")"
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Round o, collector
        collector << "ROUND("
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        if o.expressions.length == 1
          collector << LOADED_VISITOR::COMMA
          collector << "0"
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "CHARINDEX("
        collector = visit o.right, collector
        collector << LOADED_VISITOR::COMMA
        collector = visit o.left, collector
        collector << ")"
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
        collector << 'TRIM( '
        collector = visit o.right, collector
        collector << " FROM "
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        if o.right
          collector << "REPLACE(REPLACE(LTRIM(REPLACE(REPLACE("
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << "LTRIM("
          collector = visit o.left, collector
          collector << ")"
        end
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        if o.right
          collector << "REPLACE(REPLACE(RTRIM(REPLACE(REPLACE("
          collector = visit o.left, collector
          collector << ", ' ', '~'), "
          collector = visit o.right, collector
          collector << ", ' ')), ' ', "
          collector = visit o.right, collector
          collector << "), '~', ' ')"
        else
          collector << "RTRIM("
          collector = visit o.left, collector
          collector << ")"
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
            collector = visit Arel::Nodes.build_quoted(src_tz), collector
            collector << ' AT TIME ZONE '
            collector = visit Arel::Nodes.build_quoted(dst_tz), collector
          when String
            collector << ') AT TIME ZONE '
            collector = visit Arel::Nodes.build_quoted(o.time_zone), collector
          end
          collector << LOADED_VISITOR::COMMA
          collector << fmt.to_s
          collector << ')'
          collector
        else
          s = StringScanner.new o.iso_format
          collector << "("
          sep = ''
          while !s.eos?
            collector << sep
            sep = ' + '
            case
            when s.scan(LOADED_VISITOR::DATE_FORMAT_REGEX)
              dir = LOADED_VISITOR::DATE_FORMAT_DIRECTIVES[s.matched]
              fmt = LOADED_VISITOR::DATE_FORMAT_FORMAT[dir]
              collector << 'TRIM('
              collector << 'FORMAT(' if fmt
              collector << 'STR('    if !fmt
              collector << 'DATEPART('
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
                collector << ") AT TIME ZONE "
                collector = visit Arel::Nodes.build_quoted(src_tz), collector
                collector << " AT TIME ZONE "
                collector = visit Arel::Nodes.build_quoted(dst_tz), collector
              when String
                collector << ") AT TIME ZONE "
                collector = visit Arel::Nodes.build_quoted(o.time_zone), collector
              end
              collector << ')'
              collector << ')'                                  if !fmt
              collector << LOADED_VISITOR::COMMA << "'#{fmt}')" if fmt
              collector << ')'
            when s.scan(/^%%/)
              collector = visit Arel::Nodes.build_quoted('%'), collector
            when s.scan(/[^%]+|./)
              collector = visit Arel::Nodes.build_quoted(s.matched), collector
            end
          end
          collector << ')'
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << "REPLACE("
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_FindInSet o, collector
        collector << "dbo.FIND_IN_SET("
        o.expressions.each_with_index { |arg, i|
          collector << LOADED_VISITOR::COMMA if i != 0
          collector = visit arg, collector
        }
        collector << ")"
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
        collector = visit o.left.collate(true,true), collector
        collector << ' LIKE '
        collector = visit o.right.collate(true,true), collector
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
        collector << " AS "

        # sometimes these values are already quoted, if they are, don't double quote it
        quote = o.right.is_a?(Arel::Nodes::SqlLiteral) && o.right[0] != '"' && o.right[-1] != '"'

        collector << '"' if quote
        collector = visit o.right, collector
        collector << '"' if quote

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

      # TODO;
      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "(STRING_AGG("
        collector = visit o.left, collector
        collector << Arel::Visitors::Oracle::COMMA
        collector =
          if o.separator && o.separator != 'NULL'
            visit o.separator, collector
          else
            visit Arel::Nodes.build_quoted(','), collector
          end
        collector << ") WITHIN GROUP (ORDER BY "
        if o.order.present?
          o.order.each_with_index do |order,i|
            collector << Arel::Visitors::Oracle::COMMA if i != 0
            collector = visit order, collector
          end
        else
          collector = visit o.left, collector
        end
        collector << "))"
        collector
      end

      def visit_ArelExtensions_Nodes_MD5 o, collector
        collector << "LOWER(CONVERT(NVARCHAR(32),HashBytes('MD5',CONVERT(VARCHAR,"
        collector = visit o.left, collector
        collector << ")),2))"
        collector
      end

      def visit_ArelExtensions_Nodes_Cast o, collector
        case o.as_attr
        when :string
          as_attr = Arel::Nodes::SqlLiteral.new('varchar')
        when :time
          as_attr = Arel::Nodes::SqlLiteral.new('time')
        when :date
          as_attr = Arel::Nodes::SqlLiteral.new('date')
        when :datetime
          as_attr = Arel::Nodes::SqlLiteral.new('datetime')
        when :number,:decimal, :float
          as_attr = Arel::Nodes::SqlLiteral.new('decimal(10,6)')
        when :int
          collector << "CAST(CAST("
          collector = visit o.left, collector
          collector << " AS decimal(10,0)) AS int)"
          return collector
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

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        col = o.left.coalesce(0)
        locale = Arel::Nodes.build_quoted(o.locale.tr('_','-'))
        param = Arel::Nodes.build_quoted("N#{o.precision}")
        sign = ArelExtensions::Nodes::Case.new.when(col<0).
                  then('-').
                  else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
        sign_length = o.flags.include?('+') || o.flags.include?(' ') ?
              Arel::Nodes.build_quoted(1) :
              ArelExtensions::Nodes::Case.new.when(col<0).then(1).else(0)

        number =
          if o.scientific_notation
            ArelExtensions::Nodes::Concat.new([
                  Arel::Nodes::NamedFunction.new('FORMAT',[
                    col.abs/Arel::Nodes.build_quoted(10).pow(col.abs.log10.floor),
                    param,
                    locale
                  ]),
                  o.type,
                  Arel::Nodes::NamedFunction.new('FORMAT',[
                    col.abs.log10.floor,
                    Arel::Nodes.build_quoted('N0'),
                    locale
                  ])
                ])
          else
            Arel::Nodes::NamedFunction.new('FORMAT',[
                Arel::Nodes.build_quoted(col.abs),
                param,
                locale
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
        full_number =
          ArelExtensions::Nodes::Concat.new([
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
        collector << (o.unbiased_estimator ? "STDEV(" : "STDEVP(")
        visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Variance o, collector
        collector << (o.unbiased_estimator ? "VAR(" : "VARP(")
        visit o.left, collector
        collector << ")"
        collector
      end


      def visit_ArelExtensions_Nodes_LevenshteinDistance o, collector
        collector << "dbo.LEVENSHTEIN_DISTANCE("
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end


      def visit_ArelExtensions_Nodes_JsonGet o,collector
        collector << 'JSON_VALUE('
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
    end
  end
end
