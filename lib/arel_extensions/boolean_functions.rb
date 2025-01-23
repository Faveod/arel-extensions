# frozen_string_literal: true

require 'arel_extensions/nodes/then'

module ArelExtensions
  module BooleanFunctions
    def ⋀(other)
      self.and(other)
    end

    def and *others
      Arel::Nodes::And.new self, others
    end

    def ⋁(other)
      self.or(other)
    end

    def or *others
      Arel::Nodes::Or.new self, others
    end

    def then(t, f = nil)
      ArelExtensions::Nodes::Then.new [self, t, f]
    end
  end
end

class Arel::Nodes::And
  include ArelExtensions::BooleanFunctions

  def self.new *children
    children =
      children.flatten.map { |c|
        c.is_a?(self) ? c.children : c
      }.flatten
    super(children)
  end
end

# For some reason, Arel's And is properly defined as variadic (it
# stores @children, and hashes it all).  However Arel's Or is defined
# as binary, with only @left and @right, and hashing only @left and @right.
#
# So reimplement its ctor and accessors.

class Arel::Nodes::Or
  include ArelExtensions::BooleanFunctions

  attr_reader :children

  def self.new *children
    children =
      children.flatten.map { |c|
        c.is_a?(self) ? c.children : c
      }.flatten
    super
  end

  def initialize *children
    @children = children
  end

  def initialize_copy(other)
    super
    @children = other.children.copy if other.children
  end

  def left
    children.first
  end

  def right
    children[1]
  end

  def hash
    children.hash
  end

  def eql?(other)
    self.class == other.class &&
      children == other.children
  end
  alias == eql?
end
