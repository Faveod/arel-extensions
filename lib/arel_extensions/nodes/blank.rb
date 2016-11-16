module ArelExtensions
  module Nodes
    class Blank < Function
    	@@return_type = :boolean

    	def initialize expr
#        	super [expr.first.coalesce('').trim.trim("\t").trim("\n")]
        	super expr
    	end
    end

    class NotBlank < Function
    	@@return_type = :boolean

    	def initialize expr
        	super expr
    	end
    end

  end
end