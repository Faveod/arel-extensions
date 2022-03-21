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
        #      arg = self.relation.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
        #      if arg == :string || arg == :text
      Arel::Nodes::Regexp.new self, convert_regexp(other)
      #      end
    end

    # NOT_REGEXP function
    # Negation of Regexp
    def !~(other)
        #      arg = self.relation.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
        #      if arg == :string || arg == :text
      Arel::Nodes::NotRegexp.new self, convert_regexp(other)
      #      end
    end

    private

    # Function used for not_regexp.
    def convert_regexp(other)
      case other
      when String
        # Do nothing.
      when Regexp
        other = other.source.gsub('\A', '^')
        other.gsub!('\z', '$')
        other.gsub!('\Z', '$')
        other.gsub!('\d', '[0-9]')
        other.gsub!('\D', '[^0-9]')
        other.gsub!('\w', '[0-9A-Za-z]')
        other.gsub!('\W', '[^A-Za-z0-9_]')
      else
        raise(ArgumentError)
      end
      Arel.quoted(other, self)
    end
  end
end
