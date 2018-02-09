module ArelExtensions
	module Nodes
		class FormattedNumber < Function		
			@@return_type = :string
			
			attr_accessor :locale, :prefix, :suffix, :flags, :scientific_notation, :width,:precision, :type
			
			def initialize expr
				# expr[1] = {:locale => 'fr_FR', :type => "e"/"f"/"d", :prefix => "$ ", :suffix => " %", :flags => " +-#0", :width => 5, :precision => 6}
				col = expr.first
				@locale = expr[1][:locale]
				@prefix = expr[1][:prefix]
				@suffix = expr[1][:suffix] 
				@width = expr[1][:width]
				@precision = expr[1][:precision]
				@type = expr[1][:type]
				@flags = expr[1][:flags]
				@scientific_notation = /[eE]/.match(expr[1][:type]) || false
				super [col]
			end
			
			def locale 
				@locale
			end
					
			def prefix
				@prefix
			end
			
			def suffix
				@suffix
			end
			
			def width
				@width
			end
			
			def precision
				@precision	
			end
			
			def type
				@type
			end
			
			def flags
				@flags
			end
			
			def scientific_notation
				@scientific_notation
			end
    	end
				
	end
end
