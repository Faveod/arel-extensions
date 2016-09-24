module ArelExtensions
  module Nodes
    class Blank < Function
      @@return_type = :boolean

    	def initialize expr
        super [expr.first.coalesce('').trim.trim("\t").trim("\n")]
    	end
    end
  end
end