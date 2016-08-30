module ArelExtensions
  module NullFunctions

    #ISNULL function lets you return an alternative value when an expression is NULL.
    def isnull(other)
      ArelExtensions::Nodes::Isnull.new self, other
    end
    # returns the first non-null expr in the expression list. You must specify at least two expressions.
    #If all occurrences of expr evaluate to null, then the function returns null.
    def coalesce *args
      args.unshift(self)
      ArelExtensions::Nodes::Coalesce.new args
    end

  end
end