module ArelExtensions
  module Aliases

    # Install an alias, if present.
    def xas other
      if other.present?
        Arel::Nodes::As.new(self, Arel.sql(other))
      else
        self
      end
    end

  end
end
