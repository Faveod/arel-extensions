module ArelExtensions
	module BooleanFunctions

		def ⋀(other)
			self.and(other)
		end

		def ⋁(other)
			self.or(other)
		end

	end
end

Arel::Nodes::And.class_eval do
  include ArelExtensions::BooleanFunctions
end

Arel::Nodes::Or.class_eval do
  include ArelExtensions::BooleanFunctions
end