require 'arel_extensions/nodes/union'
require 'arel_extensions/nodes/union_all'

module ArelExtensions
	module SetFunctions

		def +(other)
			ArelExtensions::Nodes::Union.new(self,other)
		end		

		def union(other)
			ArelExtensions::Nodes::Union.new(self,other)
		end		

		def union_all(other)
			ArelExtensions::Nodes::UnionAll.new(self,other)
		end

		def uniq
			self
		end

	end
end

Arel::Nodes::Union.class_eval do
  include ArelExtensions::SetFunctions
end

Arel::Nodes::UnionAll.class_eval do
  include ArelExtensions::SetFunctions
end
