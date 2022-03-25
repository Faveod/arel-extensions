module ArelExtensions
  module Nodes
    class UnionAll < Arel::Nodes::UnionAll
      def initialize left, right
        super(left, right)
      end

      def union_all(other)
        ArelExtensions::Nodes::UnionAll.new(self, other)
      end

      def as other
        Arel::Nodes::TableAlias.new Arel.grouping(self), Arel::Nodes::SqlLiteral.new(other.to_s)
      end
    end
  end
end
