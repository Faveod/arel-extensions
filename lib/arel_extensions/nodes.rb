require 'arel_extensions/nodes/function'
# Math functions
require 'arel_extensions/nodes/abs'
require 'arel_extensions/nodes/ceil'
require 'arel_extensions/nodes/floor'
require 'arel_extensions/nodes/round'
require 'arel_extensions/nodes/rand'
require 'arel_extensions/nodes/sum'

# String functions
require 'arel_extensions/nodes/concat' if Arel::VERSION.to_i < 7
require 'arel_extensions/nodes/length'
require 'arel_extensions/nodes/locate'
require 'arel_extensions/nodes/matches'
require 'arel_extensions/nodes/find_in_set'
require 'arel_extensions/nodes/replace'
require 'arel_extensions/nodes/soundex'
require 'arel_extensions/nodes/trim'
require 'arel_extensions/nodes/ltrim'
require 'arel_extensions/nodes/rtrim'


require 'arel_extensions/nodes/coalesce'
require 'arel_extensions/nodes/date_diff'
require 'arel_extensions/nodes/duration'
require 'arel_extensions/nodes/isnull'
require 'arel_extensions/nodes/wday'


if Arel::VERSION.to_i < 6
	module Arel
	  module Nodes
	    class Casted < Arel::Nodes::Node # :nodoc:
	      attr_reader :val, :attribute
	      def initialize val, attribute
	        @val       = val
	        @attribute = attribute
	        super()
	      end

	      def nil?; @val.nil?; end

	      def hash
	        [self.class, val, attribute].hash
	      end

	      def eql? other
	        self.class == other.class &&
	            self.val == other.val &&
	            self.attribute == other.attribute
	      end
	      alias :== :eql?
	    end

	    class Quoted < Arel::Nodes::Unary # :nodoc:
	      alias :val :value
	      def nil?; val.nil?; end
	    end

	    def self.build_quoted other, attribute = nil
	      case other
	        when Arel::Nodes::Node, Arel::Attributes::Attribute, Arel::Table, Arel::Nodes::BindParam, Arel::SelectManager, Arel::Nodes::Quoted
	          other
	        else
	          case attribute
	            when Arel::Attributes::Attribute
	              Casted.new other, attribute
	            else
	              Quoted.new other
	          end
	      end
	    end
	  end
	end
end