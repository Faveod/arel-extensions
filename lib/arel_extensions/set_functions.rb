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

class Arel::Nodes::Union
  include ArelExtensions::SetFunctions
end

class Arel::Nodes::UnionAll
  include ArelExtensions::SetFunctions
end
