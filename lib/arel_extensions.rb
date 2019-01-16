require 'arel'

require 'arel_extensions/railtie' if defined?(Rails::Railtie)

# UnaryOperation|Grouping|Extract < Unary < Arel::Nodes::Node
# Equality|Regexp|Matches < Binary < Arel::Nodes::Node
# Count|NamedFunction < Function < Arel::Nodes::Node

# pure Arel internals improvements
Arel::Nodes::Binary.class_eval do
  include Arel::AliasPredication
  include Arel::Expressions
end

Arel::Nodes::Casted.class_eval do
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
  include Arel::OrderPredications
  include Arel::Expressions
end

Arel::Nodes::Function.class_eval do
  include Arel::Math
  include Arel::Expressions
end

if Arel::VERSION >= "7.1.0"
  Arel::Nodes::Case.class_eval do
    include Arel::Math
    include Arel::Expressions
  end
end

require 'arel_extensions/version'
require 'arel_extensions/attributes'
require 'arel_extensions/visitors'
require 'arel_extensions/nodes'
require 'arel_extensions/comparators'
require 'arel_extensions/date_duration'
require 'arel_extensions/null_functions'
require 'arel_extensions/boolean_functions'
require 'arel_extensions/math'
require 'arel_extensions/math_functions'
require 'arel_extensions/string_functions'
require 'arel_extensions/set_functions'
require 'arel_extensions/predications'

require 'arel_extensions/insert_manager'

require 'arel_extensions/common_sql_functions'

require 'arel_extensions/nodes/union'
require 'arel_extensions/nodes/union_all'
require 'arel_extensions/nodes/as'
require 'arel_extensions/nodes/case'
require 'arel_extensions/nodes/soundex'
require 'arel_extensions/nodes/cast'



module Arel
  def self.rand
    ArelExtensions::Nodes::Rand.new
  end
  
  def self.shorten s
	Base64.urlsafe_encode64(Digest::MD5.new.digest(s)).tr('=', '').tr('-', '_')
  end  
end

Arel::Attributes::Attribute.class_eval do
  include Arel::Math
  include ArelExtensions::Attributes
end

Arel::Nodes::Function.class_eval do
  include ArelExtensions::Math
  include ArelExtensions::Comparators
  include ArelExtensions::DateDuration
  include ArelExtensions::MathFunctions
  include ArelExtensions::StringFunctions
  include ArelExtensions::BooleanFunctions
  include ArelExtensions::NullFunctions
  include ArelExtensions::Predications
end

Arel::Nodes::Unary.class_eval do
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::Predications
end

Arel::Nodes::Binary.class_eval do
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::BooleanFunctions
  include ArelExtensions::Predications
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

Arel::SelectManager.class_eval do
  include ArelExtensions::SetFunctions
  include ArelExtensions::Nodes
end

Arel::Nodes::As.class_eval do	
  include ArelExtensions::Nodes
end


