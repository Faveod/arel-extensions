module ArelExtensions
	module Nodes
		class Cast < Function  
			@return_type = :string

			attr_accessor :as_attr

			def initialize expr 
				@as_attr = expr[1]
				case expr[1]
				when 'bigint', 'int', 'smallint', 'tinyint', 'bit'
					@return_type= :int
				when 'decimal', 'numeric', 'money', 'smallmoney', 'float', 'real'
					@return_type= :decimal
				when 'char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'			
					@return_type= :string		
				when :int 
					@return_type= :number			
				when :float, :decimal
					@return_type= :decimal
				when :datetime, 'datetime','smalldatetime'
					@return_type= :datetime
				when :time,'time'
					@return_type= :time
				when :date,'date'
					@return_type= :date
				when :binary, 'binary', 'varbinary', 'image'
					@return_type= :binary	
				else
					@return_type= :string
					@as_attr = :string
				end
				tab = [convert_to_node(expr.first)]
				return super(tab)
			end

			def +(other)
				case @return_type
				when :string
					return ArelExtensions::Nodes::Concat.new [self, other]
				when :ruby_time
					ArelExtensions::Nodes::DateAdd.new [self, other]
				else
					Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
				end
			end
			
			def return_type
				@return_type
			end			
			
		end
	end
end
