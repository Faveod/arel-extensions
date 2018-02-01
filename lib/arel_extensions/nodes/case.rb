module ArelExtensions
	module Nodes    
		if Arel::VERSION.to_i < 7 
			class Case < Arel::Nodes::Node
				include Arel::Expressions
				include ArelExtensions::Comparators
				include ArelExtensions::Predications	

				attr_accessor :case, :conditions, :default

				def initialize expression = nil, default = nil
					@case = expression
					@conditions = []
					@default = default
				end

				def when condition, expression = nil
					@conditions << When.new(Arel::Nodes.build_quoted(condition), expression)
					self
				end

				def then expression
					@conditions.last.right = Arel::Nodes.build_quoted(expression)
					self
				end

				def else expression
					@default = Else.new Arel::Nodes.build_quoted(expression)
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
			
			class When < Arel::Nodes::Binary # :nodoc:
			end

			class Else < Arel::Nodes::Unary # :nodoc:
			end		
			
		else
		
			class Case < Arel::Nodes::Case		
				
			end
			
		end		

	end
end
