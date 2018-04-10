module ArelExtensions
  module Nodes
    class Collate < Function
	  RETURN_TYPE = :string
	  
	  attr_accessor :ai, :ci
	  
	  def initialize left, ai=false, ci=false, others=nil
		@ai = ai
		@ci = ci
        tab = [convert_to_node(left)]
        return super(tab)
	  end
    
    end
  end
end
