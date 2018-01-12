module ArelExtensions
	module Predications
		
		def when right
			Nodes::Case.new(self).when(right)
		end	
		
	end
end
