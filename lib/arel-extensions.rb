require 'arel'

# UnaryOperation|Grouping|Extract < Unary < Arel::Nodes::Node
# Equality|Regexp|Matches < Binary < Arel::Nodes::Node
# Count|NamedFunction < Function < Arel::Nodes::Node

# pure Arel internals improvements
Arel::Nodes::Binary.class_eval do
  include Arel::AliasPredication
end

Arel::Nodes::Unary.class_eval do
  include Arel::Math
  include Arel::AliasPredication
  include Arel::Expressions
end

Arel::Nodes::Grouping.class_eval do
  include Arel::Math
  include Arel::AliasPredication
  include Arel::Expressions
end

Arel::Nodes::Function.class_eval do
  include Arel::Math
  include Arel::Expressions
end

require 'arel-extensions/version'
require 'arel-extensions/attributes'
require 'arel-extensions/visitors'
require 'arel-extensions/nodes'
require 'arel-extensions/comparators'
require 'arel-extensions/date_duration'
require 'arel-extensions/null_functions'
require 'arel-extensions/math'
require 'arel-extensions/math_functions'
require 'arel-extensions/string_functions'

require 'arel-extensions/insert_manager'

module Arel
  def self.rand
    ArelExtensions::Nodes::Rand.new
  end
end

Arel::Attributes::Attribute.class_eval do
  include Arel::Math
  include ArelExtensions::Attributes
end

Arel::Nodes::Function.class_eval do
  include ArelExtensions::Comparators
  include ArelExtensions::DateDuration
  include ArelExtensions::MathFunctions
  include ArelExtensions::StringFunctions
end

Arel::Nodes::Unary.class_eval do
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
end

Arel::Nodes::Binary.class_eval do
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
end

Arel::Nodes::Equality.class_eval do
  include ArelExtensions::Comparators
  include ArelExtensions::DateDuration
  include ArelExtensions::MathFunctions
  include ArelExtensions::StringFunctions
end


Arel::InsertManager.class_eval do
  include ArelExtensions::InsertManager
end