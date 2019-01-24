module ArelExtensions
  module Nodes
    class UnionAll < Arel::Nodes::UnionAll

      def initialize left,right
        return super(left,right)
      end

      def union_all(other)
        return ArelExtensions::Nodes::UnionAll.new(self,other) 
      end

      def as other
        Arel::Nodes::TableAlias.new Arel::Nodes::Grouping.new(self), Arel::Nodes::SqlLiteral.new(other.to_s)
      end
    end

  end
end

