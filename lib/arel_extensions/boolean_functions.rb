require 'arel_extensions/nodes/then'

module ArelExtensions
	module BooleanFunctions

		def ⋀(other)
			self.and(other)
		end

		def ⋁(other)
			self.or(other)
		end

		def then(t, f = nil)
        	ArelExtensions::Nodes::Then.new [self, t, f]
		end
	end
end

Arel::Nodes::And.class_eval do
  include ArelExtensions::BooleanFunctions
end

Arel::Nodes::Or.class_eval do
  include ArelExtensions::BooleanFunctions
end
