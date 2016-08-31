module ArelExtensions
  module MathFunctions

    # Abs function returns the absolute value of a number passed as argument #
    def abs
        ArelExtensions::Nodes::Abs.new [self]
    end

    # will rounded up any positive or negative decimal value within the function upwards #
    def ceil
        ArelExtensions::Nodes::Ceil.new [self]
    end

    # function rounded up any positive or negative decimal value down to the next least integer
    def floor
        ArelExtensions::Nodes::Floor.new [self]
    end

    #function that can be invoked to produce random numbers between 0 and 1
#    def rand seed = nil
#        ArelExtensions::Nodes::Rand.new [seed]
#    end
    alias_method :random, :rand

    #function is used to round a numeric field to the number of decimals specified
    def round precision = nil
        if precision
            ArelExtensions::Nodes::Round.new [self, precision]
        else
            ArelExtensions::Nodes::Round.new [self]
        end
    end

  end
end
