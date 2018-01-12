module ArelExtensions
	module Predications
		
		def when right
			ArelExtensions::Nodes::Case.new(self).when(right)
		end	
		
	end
end
