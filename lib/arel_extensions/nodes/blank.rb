module ArelExtensions
  module Nodes
    class Blank < Function
    	RETURN_TYPE = :boolean

    	def initialize expr
#        	super [expr.first.coalesce('').trim.trim("\t").trim("\n")]
        	super expr
    	end
    end

    class NotBlank < Function
    	RETURN_TYPE = :boolean

    	def initialize expr
        	super expr
    	end
    end

  end
end
