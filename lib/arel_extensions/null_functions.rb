require 'arel_extensions/nodes/coalesce'
require 'arel_extensions/nodes/is_null'

module ArelExtensions
  module NullFunctions

    # if_present returns nil if the the value is nil or blank
    def if_present
      Arel.when(self.cast(:string).present).then(self)
    end

    # ISNULL function lets you return an alternative value when an expression is NULL.
    def is_null
      ArelExtensions::Nodes::IsNull.new [self]
    end

    # ISNOTNULL function lets you return an alternative value when an expression is NOT NULL.
    def is_not_null
      ArelExtensions::Nodes::IsNotNull.new [self]
    end

    # returns the first non-null expr in the expression list. You must specify at least two expressions.
    # If all occurrences of expr evaluate to null, then the function returns null.
    def coalesce *args
      args.unshift(self)
      ArelExtensions::Nodes::Coalesce.new args
    end

    def coalesce_blank *args
      res = Arel.when(self.cast(:string).present).then(self)
      args[0...-1].each do |a|
        val = a.is_a?(Arel::Nodes::Node) ? a : Arel.quoted(a)
        res = res.when(val.present).then(a)
      end
      res = res.else(args[-1])
      res
    end
  end
end
