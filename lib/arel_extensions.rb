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

require 'arel_extensions/version'
require 'arel_extensions/attributes'
require 'arel_extensions/visitors'
require 'arel_extensions/nodes'
require 'arel_extensions/comparators'
require 'arel_extensions/date_duration'
require 'arel_extensions/null_functions'
require 'arel_extensions/math'
require 'arel_extensions/math_functions'
require 'arel_extensions/string_functions'

require 'arel_extensions/insert_manager'

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