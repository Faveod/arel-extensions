module ArelExtensions
  module Visitors
  	Arel::Visitors::ToSql.class_eval do  


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
        if o.right && o.right != 'NULL'
          collector << Arel::Visitors::ToSql::COMMA
          collector = visit o.right, collector
        end
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
        collector << 'LENGTH(TRIM(COALESCE('
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit Arel::Nodes.build_quoted(''), collector
        collector << "))) = 0"
        collector
      end


      def visit_ArelExtensions_Nodes_NotBlank o, collector
        collector << 'LENGTH(TRIM(COALESCE('
        collector = visit o.left, collector
        collector << Arel::Visitors::ToSql::COMMA
        collector = visit Arel::Nodes.build_quoted(''), collector
        collector << "))) > 0"
        collector
      end

      def visit_ArelExtensions_Nodes_Format o, collector
        case o.col_type
        when :date, :datetime
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
        collector = visit o.left, collector
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
	
	def visit_ArelExtensions_Nodes_As o, collector
		if o.left.is_a?(ArelExtensions::Nodes::Union) || o.left.is_a?(ArelExtensions::Nodes::UnionAll)
			collector << "("
			collector = visit o.left, collector
			collector << ") "			
			visit o.right, collector
		else
			collector = visit o.left, collector
			collector << " AS "
			visit o.right, collector
		end
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

    def visit_ArelExtensions_Nodes_When o, collector
        collector << "WHEN "
        visit o.left, collector
        collector << " THEN "
        visit o.right, collector
    end

    def visit_ArelExtensions_Nodes_Else o, collector
        collector << "ELSE "
        visit o.expr, collector
    end
    
    
    
	 def visit_ArelExtensions_Nodes_FormattedNumber o, collector		
		col = o.left
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
			then(Arel::Nodes::NamedFunction.new('REPEAT',[
				Arel::Nodes.build_quoted(
					o.flags.include?('-') ? ' ' : (o.flags.include?('0') ? '0' : ' ')
				),
				Arel::Nodes.build_quoted(o.width).abs-(number.length+sign_length)
			])).
			else('')
		before = (!o.flags.include?('0'))&&(!o.flags.include?('-')) ? repeated_char : ''
		middle = (o.flags.include?('0'))&&(!o.flags.include?('-'))  ? repeated_char : ''
		after  = o.flags.include?('-') ? repeated_char : ''
		full_number =  col.when(0).then(0).else(
			ArelExtensions::Nodes::Concat.new([
				before,
				sign,
				middle,
				number,
				after
			])
		)				
		collector = visit ArelExtensions::Nodes::Concat.new([Arel::Nodes.build_quoted(o.prefix),full_number,Arel::Nodes.build_quoted(o.suffix)]), Arel::Collectors::SQLString.new
		
		collector		
	  end
		
  	end
  end
end
