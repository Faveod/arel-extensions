module ArelExtensions
  module Comparators
    def >(other)
      Arel::Nodes::GreaterThan.new self, Arel.quoted(other, self)
    end

    def >=(other)
      Arel::Nodes::GreaterThanOrEqual.new self, Arel.quoted(other, self)
    end

    def <(other)
      Arel::Nodes::LessThan.new self, Arel.quoted(other, self)
    end

    def <=(other)
      Arel::Nodes::LessThanOrEqual.new self, Arel.quoted(other, self)
    end

    # REGEXP function
    # Pattern matching using regular expressions
    def =~(other)
      Arel::Nodes::Regexp.new self, Arel.quoted(other, self)
    end

    # NOT_REGEXP function
    # Negation of Regexp
    def !~(other)
      Arel::Nodes::NotRegexp.new self, Arel.quoted(other, self)
    end
  end
end
