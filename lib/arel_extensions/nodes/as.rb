module ArelExtensions
  module Nodes
    class As < Arel::Nodes::As
    
	  def initialize left,right
        return super(left,right)
      end
    end
  end
end


