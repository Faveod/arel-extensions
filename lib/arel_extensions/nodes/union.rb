module ArelExtensions
  module Nodes
    class Union < Arel::Nodes::Union

      def initialize left,right
        return super(left,right)
      end

      def +(other)
        return ArelExtensions::Nodes::Union.new(self,other) 
      end
      
      def as other
        ArelExtensions::Nodes::As.new self, Arel::Nodes::SqlLiteral.new(other.to_s)
      end
    end
    
  end
end

