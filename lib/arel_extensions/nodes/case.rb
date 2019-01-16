module ArelExtensions
	module Nodes    
		if Arel::VERSION < "7.1.0"
			class Case < Arel::Nodes::Node
				attr_accessor :case, :conditions, :default

				def initialize expression = nil, default = nil
					@case = expression
					@conditions = []
					@default = default
				end

				class When < Arel::Nodes::Binary # :nodoc:
				end

				class Else < Arel::Nodes::Unary # :nodoc:
				end

			end
		else
			class Case < Arel::Nodes::Case
				class When < Arel::Nodes::When # :nodoc:
				end
				class Else < Arel::Nodes::Else # :nodoc:
				end
			end
		end

		ArelExtensions::Nodes::Case.class_eval do
			include Arel::Expressions
			include Arel::OrderPredications
			include ArelExtensions::Math
			include ArelExtensions::Comparators
			include ArelExtensions::Predications
			include ArelExtensions::MathFunctions
			include ArelExtensions::StringFunctions
			include ArelExtensions::NullFunctions

			def return_type
				obj = if @conditions.length > 0
						@conditions.last.right
					elsif @default
						@default.expr
					else
						nil
					end
				if obj.respond_to?(:return_type)
					obj.return_type
				else
					case obj
					when Integer, Float
						:number
					when Date, DateTime,Time
						:datetime
					when Arel::Attributes::Attribute
						begin
							Arel::Table.engine.connection.schema_cache.columns_hash(obj.relation.table_name)[obj.name.to_s].cast_type.type
						rescue Exception
							:string
						end
					else
						:string
					end
				end
			end

			def when condition, expression = nil
				@conditions << Case::When.new(condition, expression)
				self
			end

			def then expression
				@conditions.last.right = expression
				self
			end

			def else expression
				@default = Case::Else.new expression
				self
			end

			def initialize_copy other
				super
				@case = @case.clone if @case
				@conditions = @conditions.map { |x| x.clone }
				@default = @default.clone if @default
			end

			def hash
				[@case, @conditions, @default].hash
			end

			def eql? other
				self.class == other.class &&
				self.case == other.case &&
				self.conditions == other.conditions &&
				self.default == other.default
			end
			alias :== :eql?

			def as other
				ArelExtensions::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other)
			end
		end
	end
end
