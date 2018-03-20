module ArelExtensions
	module Nodes
		class Cast < Function  
			@@return_type= :string

			attr_accessor :as_attr

			def initialize expr 
				@as_attr = expr[1]
				case expr[1]
				when 'bigint', 'int', 'smallint', 'tinyint', 'bit', 'decimal', 'numeric', 'money', 'smallmoney', 'float', 'real'
					@@return_type= :number
				when 'datetime', 'smalldatetime','time','date'		
					@@return_type= :ruby_time
				when 'char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext'
					@@return_type= :string
				when 'binary', 'varbinary', 'image'
					@@return_type= :binary			
				when :number 
					@@return_type= :number
					#as_attr = 'int'
				when :datetime 
					@@return_type= :ruby_time
					#as_attr = 'datetime'
				when :string 
					@@return_type= :string
					#as_attr = 'char' 
				when :binary
					@@return_type= :binary			
					#as_attr = 'binary'
				else
					@@return_type= :string
					#as_attr =  'char'
					@as_attr = :string
				end
				tab = [convert_to_node(expr.first)]
				return super(tab)
			end

			def +(other)
				case @@return_type
				when :string
					return ArelExtensions::Nodes::Concat.new [self, other]
				when :ruby_time
					ArelExtensions::Nodes::DateAdd.new [self, other]
				else
					Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
				end
			end
		end
	end
end
