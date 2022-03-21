module ArelExtensions
  module Nodes
    class Soundex < Function
      include Arel::Expressions
      include ArelExtensions::Comparators

      RETURN_TYPE = :string

      def ==(other)
        Arel::Nodes::Equality.new self, Arel.quoted(other, self)
      end

      def !=(other)
        Arel::Nodes::NotEqual.new self, Arel.quoted(other, self)
      end
    end
  end
end
