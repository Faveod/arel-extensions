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
        if o.right && o.right != 'NULL'
          collector << ' SEPARATOR '
          collector = visit o.right, collector
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
        collector << if o.left_node_type == :ruby_time || o.left_node_type == :datetime || o.left_node_type == :time
                      'TIMESTAMPDIFF(SECOND, '
                    else
                      'DATEDIFF('
                    end
        collector = visit o.right, collector
        collector << Arel::Visitors::MySQL::COMMA
        collector = visit o.left, collector
        collector << ")"
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
          collector << "#{Arel::Visitors::MySQL::DATE_MAPPING[o.left]}("
          collector = visit o.right, collector
          collector << ")"
        end
        collector
      end


      def visit_ArelExtensions_Nodes_IsNull o, collector
        collector << "ISNULL("
        collector = visit o.left, collector
        if o.right
          collector << Arel::Visitors::MySQL::COMMA
          collector = visit o.right, collector
        end
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

		alias_method :old_visit_Arel_Nodes_SelectStatement, :visit_Arel_Nodes_SelectStatement
		def visit_Arel_Nodes_SelectStatement o, collector	
			if !collector.value.blank? && o.limit.blank? && o.offset.blank? 				
				o = o.dup
				o.orders = []
			end
			old_visit_Arel_Nodes_SelectStatement(o,collector)
		end	

    end
  end
end
