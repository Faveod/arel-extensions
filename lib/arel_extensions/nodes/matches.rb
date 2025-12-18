module ArelExtensions
  module Nodes
    class IMatches < Arel::Nodes::Matches
      attr_accessor :case_sensitive if AREL_VERSION < V7

      def initialize(left, right, escape = nil)
        r = Arel.quoted(right)
        if AREL_VERSION < V7 # managed by default in version 7+ (rails 5), so useful for rails 3 & 4
          super(left, r, escape)
          @case_sensitive = false
        else
          super(left, r, escape, false)
        end
      end
    end

    class IDoesNotMatch < IMatches
    end

    class AiMatches < IMatches
    end

    class AiIMatches < IMatches
    end

    class SMatches < IMatches
    end
  end
end
