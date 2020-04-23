# coding: utf-8
require 'arel_extensions/nodes/then'

module ArelExtensions
  module BooleanFunctions

    def ⋀(other)
      self.and(other)
    end

    def and *others
      build Arel::Nodes::And, others
    end

    def ⋁(other)
      self.or(other)
    end

    def or *others
      build Arel::Nodes::Or, others
    end

    def then(t, f = nil)
      ArelExtensions::Nodes::Then.new [self, t, f]
    end

    def build klass, others
      children =
        ([self] + others.flatten).map { |c|
        c.is_a?(klass) ? c.children : c
      }.flatten
      klass.new children
    end
  end
end

class Arel::Nodes::And
  include ArelExtensions::BooleanFunctions
end

# For some reason, Arel's And is properly defined as variadic (it
# stores @children, and hashes it all).  However Arel's Or is defined
# as binary, with only @left and @right, and hashing only @left and @right.
#
# So reimplement its ctor and accessors.

class Arel::Nodes::Or
  include ArelExtensions::BooleanFunctions

  attr_reader :children

  def initialize *children
    @children = children.flatten
  end

  def hash
    children.hash
  end

  def eql? other
    self.class == other.class &&
      self.children == other.children
  end
  alias :== :eql?
end
