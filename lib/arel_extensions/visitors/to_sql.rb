module ArelExtensions
  module Visitors
    Arel::Visitors::ToSql.class_eval do
      Arel::Visitors::ToSql::COMMA = ', ' unless defined?(Arel::Visitors::ToSql::COMMA)

      # Math Functions
      def visit_ArelExtensions_Nodes_Abs o, collector
        collector << "ABS("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ceil o, collector
        collector << "CEIL("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Floor o, collector
        collector << "FLOOR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << "RAND("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Round o, collector
        collector << "ROUND("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Log10 o, collector
        collector << "LOG10("
        collector = visit o.left, collector
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

      def visit_ArelExtensions_Nodes_Sum o, collector
        collector << "SUM("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

      # String functions
      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << "CONCAT("
      o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "GROUP_CONCAT("
        collector = visit o.left, collector
        if o.separator && o.separator != 'NULL'
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.separator, collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_MD5 o, collector
        collector << "MD5("
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Length o, collector
        collector << "LENGTH("
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "LOCATE("
        collector = visit o.right, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << "SUBSTRING("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Replace o, collector
        collector << "REPLACE("
        visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        visit o.pattern, collector
        collector << Arel::Visitors::ToSql::COMMA
        visit o.substitute, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_RegexpReplace o, collector
        collector << "REGEXP_REPLACE("
        visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        visit Arel::Nodes.build_quoted(o.pattern.to_s), collector
        collector << Arel::Visitors::ToSql::COMMA
        visit o.substitute, collector
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

      def visit_ArelExtensions_Nodes_FindInSet o, collector
        collector << "FIND_IN_SET("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Soundex o, collector
        collector << "SOUNDEX("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Downcase o, collector
        collector << "LOWER("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Upcase o, collector
        collector << "UPPER("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
        collector << "TRIM("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Ltrim o, collector
        collector << "LTRIM("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Rtrim o, collector
        collector << "RTRIM("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Blank o, collector
    #visit o.left.coalesce('').trim.length.eq(0), collector
        collector << 'LENGTH(TRIM(COALESCE('
        collector = visit o.expr, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit Arel::Nodes.build_quoted(''), collector
        collector << "))) = 0"
        collector
      end


      def visit_ArelExtensions_Nodes_NotBlank o, collector
    #visit o.left.coalesce('').trim.length.gt(0), collector
        collector << 'LENGTH(TRIM(COALESCE('
        collector = visit o.expr, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit Arel::Nodes.build_quoted(''), collector
        collector << "))) > 0"
        collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime, :time
          collector << "STRFTIME("
          collector = visit o.right, collector
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.left, collector
          collector << ")"
        when :integer, :float, :decimal
          collector << "FORMAT("
          collector = visit o.left, collector
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.right, collector
          collector << ")"
        else
          collector = visit o.left, collector
        end
        collector
      end

      #comparators

      def visit_ArelExtensions_Nodes_Cast o, collector
        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
        case o.as_attr
        when :string
          as_attr = Arel::Nodes::SqlLiteral.new('char')
        when :int
          as_attr = Arel::Nodes::SqlLiteral.new('int')
        when :decimal, :float, :number
          as_attr = Arel::Nodes::SqlLiteral.new('float')
        when :datetime
          as_attr = Arel::Nodes::SqlLiteral.new('datetime')
        when :time
          as_attr = Arel::Nodes::SqlLiteral.new('time')
        when :binary
          as_attr = Arel::Nodes::SqlLiteral.new('binary')
        else
          as_attr = Arel::Nodes::SqlLiteral.new(o.as_attr.to_s)
        end
        collector = visit as_attr, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Coalesce o, collector
        collector << "COALESCE("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                      'TIMEDIFF('
                    else
                      'DATEDIFF('
                    end
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_DateSub o, collector
        collector << "DATE_SUB("
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ")"
        collector
      end

        # override
      remove_method(:visit_Arel_Nodes_As) rescue nil # if Arel::Visitors::ToSql.method_defined?(:visit_Arel_Nodes_As)
      def visit_Arel_Nodes_As o, collector
        if o.left.is_a?(Arel::Nodes::Binary)
          collector << '('
          collector = visit o.left, collector
          collector << ')'
        else
          collector = visit o.left, collector
        end
        collector << " AS "
        collector = visit o.right, collector
        collector
      end

      remove_method(:visit_Arel_Nodes_Regexp) rescue nil # if Arel::Visitors::ToSql.method_defined?(:visit_Arel_Nodes_Regexp)
      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << " REGEXP "
        collector = visit o.right, collector
        collector
      end

      remove_method(:visit_Arel_Nodes_NotRegexp) rescue nil # if Arel::Visitors::ToSql.method_defined?(:visit_Arel_Nodes_NotRegexp)
      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << " NOT REGEXP "
        collector = visit o.right, collector
        collector
      end

      def visit_ArelExtensions_Nodes_IMatches o, collector
        collector = infix_value o, collector, ' ILIKE '
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_ArelExtensions_Nodes_IDoesNotMatch o, collector
        collector = infix_value o, collector, ' NOT ILIKE '
        if o.escape
          collector << ' ESCAPE '
          collector = visit o.escape, collector
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

      def visit_ArelExtensions_Nodes_Then o, collector
        collector << "CASE WHEN ("
        collector = visit o.left, collector
        collector << ") THEN "
        collector = visit o.right, collector
        if o.expressions[2]
          collector << " ELSE "
          collector = visit o.expressions[2], collector
        end
        collector << " END"
        collector
      end

      # Date operations
      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector << "DATE_ADD("
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.sqlite_value(o.right), collector
        collector << ')'
        collector
      end

      if Arel::VERSION.to_i < 7
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          collector << 'VALUES '
          row_nb = o.left.length
          o.left.each_with_index do |row, idx|
            collector << '('
            v = Arel::Nodes::Values.new(row, o.cols)
            len = v.expressions.length - 1
            v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
                case value
                when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                  collector = visit value, collector
                else
                  collector << quote(value, attr && column_for(attr)).to_s
                end
                collector << Arel::Visitors::ToSql::COMMA unless i == len
            }
            collector << (idx == row_nb-1 ? ')' : '), ')
          end
          collector
        end
      else
        def visit_ArelExtensions_InsertManager_BulkValues o, collector
          collector << 'VALUES '
          row_nb = o.left.length
          o.left.each_with_index do |row, idx|
            collector << '('
            v = Arel::Nodes::Values.new(row, o.cols)
            len = v.expressions.length - 1
            v.expressions.zip(v.columns).each_with_index { |(value, attr), i|
                case value
                when Arel::Nodes::SqlLiteral, Arel::Nodes::BindParam
                  collector = visit value, collector
                else
                  collector << (attr && attr.able_to_type_cast? ? quote(attr.type_cast_for_database(value)) : quote(value).to_s)
                end
                collector << Arel::Visitors::ToSql::COMMA unless i == len
            }
            collector << (idx == row_nb-1 ? ')' : '), ')
          end
          collector
        end
      end

      def visit_ArelExtensions_Nodes_Union o, collector
        collector = visit o.left, collector
        collector << " UNION "
        collector = visit o.right, collector
        collector
      end

      def visit_ArelExtensions_Nodes_UnionAll o, collector
        collector = visit o.left, collector
        collector << " UNION ALL "
        collector = visit o.right, collector
        collector
      end

      def visit_ArelExtensions_Nodes_Case o, collector
        collector << "CASE "
        if o.case
          visit o.case, collector
          collector << " "
        end
        o.conditions.each do |condition|
          visit condition, collector
          collector << " "
        end
        if o.default
          visit o.default, collector
          collector << " "
        end
        collector << "END"
      end

      def visit_ArelExtensions_Nodes_Case_When o, collector
        collector << "WHEN "
        visit Arel::Nodes.build_quoted(o.left), collector
        collector << " THEN "
        visit Arel::Nodes.build_quoted(o.right), collector
      end

      def visit_ArelExtensions_Nodes_Case_Else o, collector
        collector << "ELSE "
        visit Arel::Nodes.build_quoted(o.expr), collector
      end

      def visit_ArelExtensions_Nodes_FormattedNumber o, collector
        visit o.left, collector
      end

      remove_method(:visit_Arel_Nodes_LessThan) rescue nil
      def visit_Arel_Nodes_LessThan o, collector
        collector = visit o.left, collector
        collector << " < "
        visit o.right, collector
      end

      def visit_ArelExtensions_Nodes_Std o, collector
        collector << "STD("
        visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Variance o, collector
        collector << "VARIANCE("
        visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_LevenshteinDistance o, collector
        collector << "LEVENSHTEIN_DISTANCE("
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      alias_method :old_visit_Arel_Nodes_And, :visit_Arel_Nodes_And
      def visit_Arel_Nodes_And o, collector
        collector << '('
        case o.children.length
        when 0
          collector << '1=1' # but this should not happen
        when 1
          collector = visit o.children[0], collector
        else
          o.children.each_with_index { |arg, i|
            if i != 0
              collector << ') AND ('
            end
            collector = visit arg, collector
          }
        end
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Or o, collector
        collector << '('
        case o.children.length
        when 0
          collector << '0=1' # but this should not happen
        when 1
          collector = visit o.children[0], collector
        else
            o.children.each_with_index { |arg, i|
              if i != 0
                collector << ') OR ('
              end
              collector = visit arg, collector
            }
        end
        collector << ')'
        collector
      end

      alias_method :old_visit_Arel_Nodes_Or, :visit_Arel_Nodes_Or
      def visit_Arel_Nodes_Or o, collector
        collector << '('
        collector = visit o.left, collector
        collector << ') OR ('
        collector = visit o.right, collector
        collector << ')'
        collector
      end

      def visit_ArelExtensions_Nodes_Json o,collector
        case o.dict
        when Array
          res = Arel::Nodes.build_quoted('[')
          o.dict.each.with_index do |v,i|
            if i != 0
              res += ', '
            end
            if (v.is_a?(Arel::Attributes::Attribute) && o.type_of_attribute(v) == :string) || (v.return_type == :string)
              res = res + '"' + v + '"'
            else
              res += v
            end
          end
          res += ']'
          collector = visit res, collector
        when Hash
          res = Arel::Nodes.build_quoted('{')
          o.dict.each.with_index do |(k,v),i|
            if i != 0
              res += ', '
            end
            res += Arel::Nodes.build_quoted('"')+k + '": '
            if (v.is_a?(Arel::Attributes::Attribute) && o.type_of_attribute(v) == :string) || (v.respond_to?(:return_type) && v.return_type == :string)
              res = res + '"' + v + '"'
            else
              res += v
            end
          end
          res += '}'
          collector = visit res, collector
        else
          collector = visit o.dict, collector
        end
        collector
      end

      def visit_ArelExtensions_Nodes_JsonGroup o, collector
        if o.as_array
          res = Arel::Nodes.build_quoted('[') + (o.orders ? o.dict.group_concat(', ',o.orders) : o.dict.group_concat(', ')) + ']'
          collector = visit res, collector
        else
          res = Arel::Nodes.build_quoted('{')
          orders = o.orders || o.dict.keys
          o.dict.each.with_index do |(k,v),i|
            if i != 0
              res = res + ', '
            end
            kv = Arel::Nodes.build_quoted('"')+k + '": '
            if (v.is_a?(Arel::Attributes::Attribute) && o.type_of_attribute(v) == :string) || (v.respond_to?(:return_type) && v.return_type == :string)
              kv = kv + '"' + v + '"'
            else
              kv += v
            end
            res = res + kv.group_concat(', ',orders)
          end
          res = res + '}'
          collector = visit res, collector
        end
        collector
      end

    end
  end
end
