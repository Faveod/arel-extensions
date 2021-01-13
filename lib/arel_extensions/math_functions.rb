require 'arel_extensions/nodes/abs'
require 'arel_extensions/nodes/ceil'
require 'arel_extensions/nodes/floor'
require 'arel_extensions/nodes/round'
require 'arel_extensions/nodes/rand'
require 'arel_extensions/nodes/formatted_number'
require 'arel_extensions/nodes/log10'
require 'arel_extensions/nodes/power'
require 'arel_extensions/nodes/std'
require 'arel_extensions/nodes/sum'

module ArelExtensions
  module MathFunctions
    # Arel does not handle Decimal literal properly
    def * other
      case other
      when Float, BigDecimal
        super(Arel::Nodes.build_quoted(other))
      else
        super(other)
      end
    end

    # Arel does not handle Decimal literal properly
    def / other
      case other
      when Float, BigDecimal
        super(Arel::Nodes.build_quoted(other))
      else
        super(other)
      end
    end

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

    # function gives the base 10 log
    def log10
        ArelExtensions::Nodes::Log10.new [self]
    end

    # function gives the power of a number
    def pow exposant = 0
        ArelExtensions::Nodes::Power.new [self,exposant]
    end

    # function gives the power of a number
    def power exposant = 0
        ArelExtensions::Nodes::Power.new [self,exposant]
    end

    # Aggregate Functions
    def std opts = {unbiased: true}
      ArelExtensions::Nodes::Std.new self, **opts
    end

    def variance opts = {unbiased: true}
      ArelExtensions::Nodes::Variance.new self, **opts
    end

    def sum opts = {unbiased: true}
      if Gem::Version.new(Arel::VERSION) >= Gem::Version.new("9.0.0")
        Arel::Nodes::Sum.new self
      else
        ArelExtensions::Nodes::Sum.new self, **opts
      end
    end

    # function that can be invoked to produce random numbers between 0 and 1
    #    def rand seed = nil
    #        ArelExtensions::Nodes::Rand.new [seed]
    #    end
    alias_method(:random, :rand) rescue nil

    # function is used to round a numeric field to the number of decimals specified
    def round precision = nil
        if precision
            ArelExtensions::Nodes::Round.new [self, precision]
        else
            ArelExtensions::Nodes::Round.new [self]
        end
    end

    # function returning a number at a specific format
    def format_number format_string, locale = nil
      begin
        sprintf(format_string,0) # this line is to get the right error message if the format_string is not correct
        m = /^(.*)%([ #+\-0]*)([1-9][0-9]+|[1-9]?)[.]?([0-9]*)([a-zA-Z])(.*)$/.match(format_string)
        opts = {
          prefix: m[1],
          flags: m[2].split(//).uniq.join,
          width: m[3].to_i,
          precision: m[4] != '' ? m[4].to_i : 6,
          type: m[5],
          suffix: m[6],
          locale: locale,
          original_string: format_string
        }
        # opts = {:locale => 'fr_FR', :type => "e"/"f"/"d", :prefix => "$ ", :suffix => " %", :flags => " +-#0", :width => 5, :precision => 6}
        ArelExtensions::Nodes::FormattedNumber.new [self,opts]
      rescue Exception
        Arel::Nodes.build_quoted('Wrong Format')
      end
    end
  end
end
