module ArelExtensions
  module Nodes
    class Union < Arel::Nodes::Union
      def initialize left, right
        return super(left, right)
      end

      def +(other)
        return ArelExtensions::Nodes::Union.new(self, other)
      end

      def union(other)
        return ArelExtensions::Nodes::UnionAll.new(self, other)
      end

      def as other
        Arel::Nodes::TableAlias.new Arel.grouping(self), Arel::Nodes::SqlLiteral.new(other.to_s)
      end
    end
  end
end
