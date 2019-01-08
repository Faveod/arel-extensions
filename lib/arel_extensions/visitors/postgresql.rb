module ArelExtensions
  module Visitors
    Arel::Visitors::PostgreSQL.class_eval do
      Arel::Visitors::PostgreSQL::DATE_MAPPING = {'d' => 'DAY', 'm' => 'MONTH', 'w' => 'WEEK', 'y' => 'YEAR', 'wd' => 'DOW', 'h' => 'HOUR', 'mn' => 'MINUTE', 's' => 'SECOND'}
      Arel::Visitors::PostgreSQL::DATE_FORMAT_DIRECTIVES = {
        '%Y' => 'IYYY', '%C' => 'CC', '%y' => 'YY', '%m' => 'MM', '%B' => 'Month', '%^B' => 'MONTH', '%b' => 'Mon', '%^b' => 'MON',
        '%d' => 'DD', '%e' => 'FMDD', '%j' => 'DDD', '%w' => '', '%A' => 'Day', # day, weekday
        '%H' => 'HH24', '%k' => '', '%I' => 'HH', '%l' => '', '%P' => 'am', '%p' => 'AM', # hours
        '%M' => 'MI', '%S' => 'SS', '%L' => 'MS', '%N' => 'US', '%z' => 'tz' # seconds, subseconds
      }
      Arel::Visitors::PostgreSQL::NUMBER_COMMA_MAPPING = { 'en_US' => '.,', 'fr_FR' => ',', 'sv_SE' => ', ' }

      def visit_ArelExtensions_Nodes_Rand o, collector
        collector << "RANDOM("
        if(o.left != nil && o.right != nil)
          collector = visit o.left, collector
          collector << Arel::Visitors::PostgreSQL::COMMA
          collector = isit o.right, collector
        end
        collector << ")"
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
      
      def visit_ArelExtensions_Nodes_Log10 o, collector
        collector << "LOG("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::ToSql::COMMA unless i == 0
          collector = visit arg, collector
        }
        collector << ")"
        collector
      end
	  

      remove_method(:visit_Arel_Nodes_Regexp) rescue nil
      def visit_Arel_Nodes_Regexp o, collector
        collector = visit o.left, collector
        collector << " ~ "
        collector = visit o.right, collector
        collector
      end

      remove_method(:visit_Arel_Nodes_NotRegexp) rescue nil
      def visit_Arel_Nodes_NotRegexp o, collector
        collector = visit o.left, collector
        collector << " !~ "
        collector = visit o.right, collector
        collector
      end
      
      def visit_ArelExtensions_Nodes_Concat o, collector
        collector << '('
        o.expressions.each_with_index { |arg, i|
          collector = visit arg, collector
          collector << ' || ' unless i == o.expressions.length - 1
        }
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_GroupConcat o, collector
        collector << "array_to_string(array_agg("
        collector = visit o.left, collector
        collector << ")"
        if o.right  && o.right != 'NULL'
          collector << Arel::Visitors::PostgreSQL::COMMA
          collector = visit o.right, collector
        else
          collector << Arel::Visitors::PostgreSQL::COMMA
          collector = visit Arel::Nodes.build_quoted(' '), collector
        end
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Trim o, collector
          collector << 'TRIM(BOTH '
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

      def visit_ArelExtensions_Nodes_Format o, collector
        collector << "TO_CHAR("
        collector = visit o.left, collector
        collector << Arel::Visitors::PostgreSQL::COMMA

        f = o.iso_format.dup
        Arel::Visitors::PostgreSQL::DATE_FORMAT_DIRECTIVES.each { |d, r| f.gsub!(d, r) }
        collector = visit Arel::Nodes.build_quoted(f), collector

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
        collector << ' ILIKE '
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
      
	  def visit_ArelExtensions_Nodes_Collate o, collector        
		if o.ai
			collector << "unaccent("
			collector = visit o.expressions.first, collector
			collector << ")"
		elsif o.ci
			collector = visit o.expressions.first, collector
		else
			collector = visit o.expressions.first, collector
		end       
        collector
	  end

      def visit_ArelExtensions_Nodes_DateAdd o, collector
        collector = visit o.left, collector
        collector << (o.right.value >= 0 ? ' + ' : ' - ')
        collector = visit o.postgresql_value(o.right), collector
        collector
      end

      def visit_ArelExtensions_Nodes_DateDiff o, collector
        collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                        "DATEDIFF('second', "
                    else
                        "DATEDIFF('day', "
                    end
        collector = visit o.right, collector
        collector << (o.right_node_type == :date ? '::date' : '::timestamp')
        collector << Arel::Visitors::PostgreSQL::COMMA
        collector = visit o.left, collector
        collector << (o.left_node_type == :date ? '::date' : '::timestamp')
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Duration o, collector
        collector << "EXTRACT(#{Arel::Visitors::PostgreSQL::DATE_MAPPING[o.left]} FROM "
        collector = visit o.right, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Locate o, collector
        collector << "POSITION("
        collector = visit o.right, collector
        collector << " IN "
        collector = visit o.left, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Substring o, collector
        collector << "SUBSTR("
        o.expressions.each_with_index { |arg, i|
          collector << Arel::Visitors::PostgreSQL::COMMA unless i == 0
          collector = visit arg, collector
        }
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

      def visit_ArelExtensions_Nodes_Sum o, collector
        collector << "sum("
        collector = visit o.expr, collector
        collector << ")"
        collector
      end

      def visit_ArelExtensions_Nodes_Wday o, collector
        collector << "EXRTACT(DOW, "
        collector = visit o.date, collector
        collector << ')'
        collector
      end
      
	  def visit_ArelExtensions_Nodes_Cast o, collector
        collector << "CAST("
        collector = visit o.left, collector
        collector << " AS "
		case o.as_attr
		when :string
			as_attr = Arel::Nodes::SqlLiteral.new('varchar')
		when :time
			as_attr = Arel::Nodes::SqlLiteral.new('time')
		when :number 
			as_attr = Arel::Nodes::SqlLiteral.new('int')
		when :datetime 
			as_attr = Arel::Nodes::SqlLiteral.new('datetime')
		when :binary			
			as_attr = Arel::Nodes::SqlLiteral.new('binary')		
		else
			as_attr = Arel::Nodes::SqlLiteral.new(o.as_attr.to_s)
		end
        collector = visit as_attr, collector
        collector << ")"
        collector
	  end

	  def visit_ArelExtensions_Nodes_FormattedNumber o, collector	
			col = o.left
			comma = o.precision == 0 ? '' : (Arel::Visitors::PostgreSQL::NUMBER_COMMA_MAPPING[o.locale][0] || '.')
			thousand_separator = Arel::Visitors::PostgreSQL::NUMBER_COMMA_MAPPING[o.locale][1] || (Arel::Visitors::PostgreSQL::NUMBER_COMMA_MAPPING[o.locale] ? '' : 'G')
			nines_after = (1..o.precision).map{'9'}.join('')
			nines_before = ("999#{thousand_separator}"*4+"990")

			sign = ArelExtensions::Nodes::Case.new.when(col<0).
								then('-').
								else(o.flags.include?('+') ? '+' : (o.flags.include?(' ') ? ' ' : ''))
			sign_length = ArelExtensions::Nodes::Length.new([sign])
			
			if o.scientific_notation 
				number = ArelExtensions::Nodes::Concat.new([
								Arel::Nodes::NamedFunction.new('TRIM',[
									Arel::Nodes::NamedFunction.new('TO_CHAR',[
										col.abs/Arel::Nodes.build_quoted(10).pow(col.abs.log10.floor),
										Arel::Nodes.build_quoted('FM'+nines_before+'"'+comma+'"V'+nines_after)
									])]),
								o.type, 
								Arel::Nodes::NamedFunction.new('TRIM',[
									Arel::Nodes::NamedFunction.new('TO_CHAR',[
										col.abs.log10.floor,
										Arel::Nodes.build_quoted('FM'+nines_before)
									])])
							])
			else			
				number = Arel::Nodes::NamedFunction.new('TRIM',[
							Arel::Nodes::NamedFunction.new('TO_CHAR',[
								Arel::Nodes.build_quoted(col.abs),
								Arel::Nodes.build_quoted('FM'+nines_before+'"'+comma+'"V'+nines_after)
							])])
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
			full_number =  col.when(0).then('0').else(
				ArelExtensions::Nodes::Concat.new([
					before,
					sign,
					middle,
					number,
					after
				])
			)				
			collector = visit ArelExtensions::Nodes::Concat.new([Arel::Nodes.build_quoted(o.prefix),full_number,Arel::Nodes.build_quoted(o.suffix)]), collector
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
			if o.name.length > 63
				o = Arel::Table.new(o.table_name).alias(Arel.shorten(o.name))
			end
			old_visit_Arel_Nodes_TableAlias(o,collector)		
		end

		alias_method :old_visit_Arel_Attributes_Attribute, :visit_Arel_Attributes_Attribute  
		def visit_Arel_Attributes_Attribute o, collector			
			join_name = o.relation.table_alias || o.relation.name
			if join_name.length > 63
				join_name = Arel.shorten(join_name)
			end
			collector << "#{quote_table_name join_name}.#{quote_column_name o.name}"
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

    end
  end
end
