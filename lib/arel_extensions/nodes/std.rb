module ArelExtensions
  module Nodes
    class Std < Function
    	RETURN_TYPE = :number

		attr_accessor :unbiased_estimator
    	def initialize expr
	        col = expr.first
            @unbiased_estimator = expr[1]
        	super [col]
    	end
    end

    class Variance < Function
    	RETURN_TYPE = :number

		attr_accessor :unbiased_estimator
    	def initialize expr
	        col = expr.first
            @unbiased_estimator = expr[1]
        	super [col]
    	end
    end

  end
end
