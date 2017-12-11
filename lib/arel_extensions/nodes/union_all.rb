module ArelExtensions
  module Nodes
    class UnionAll < Arel::Nodes::UnionAll

      def initialize left,right
        return super(left,right)
      end

      def *(other)
        return ArelExtensions::Nodes::UnionAll.new(self,other) 
      end
         
      def as other
        ArelExtensions::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other.to_s)
      end
    end
    
  end
end

