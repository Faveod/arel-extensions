require 'arel_extensions/nodes/then'

module ArelExtensions
  module BooleanFunctions

    def ⋀(other)
      self.and(other)
    end

    def and *others
      Arel::Nodes::And.new([self]+ others.flatten)
    end

    def ⋁(other)
      self.or(other)
    end

    def or *others
      args = others.flatten
      if args.length == 1
        Arel::Nodes::Or.new(self, args.first)
      else
        ArelExtensions::Nodes::Or.new([self]+ args)
      end
    end

    def then(t, f = nil)
      ArelExtensions::Nodes::Then.new [self, t, f]
    end
  end
end

Arel::Nodes::And.class_eval do
  include ArelExtensions::BooleanFunctions
end

Arel::Nodes::Or.class_eval do
  include ArelExtensions::BooleanFunctions
end

ArelExtensions::Nodes.const_set('Or',Class.new(Arel::Nodes::And)).class_eval do
  include ArelExtensions::BooleanFunctions
end
