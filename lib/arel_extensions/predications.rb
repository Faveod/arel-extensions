module ArelExtensions
	module Predications
		
		if Arel::VERSION.to_i < 7 
			def when right
				ArelExtensions::Nodes::Case.new(self).when(right)
		
			end
		end	
		
	end
end
