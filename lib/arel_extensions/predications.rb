module ArelExtensions
	module Predications				
		if Arel::VERSION.to_i < 7 
			def when right
				ArelExtensions::Nodes::Case.new(self).when(right)
			end
		end
		
		def matches(other, escape=nil)
			Arel::Nodes::Matches.new(self, Arel::Nodes.build_quoted(other), escape)
		end
		
		def imatches(other, escape=nil)
			ArelExtensions::Nodes::IMatches.new(self, other, escape)
		end			
		
		def cast right	
		  ArelExtensions::Nodes::Cast.new([self,right])
		end

		
	end
end
