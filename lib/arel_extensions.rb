require 'arel'

require 'arel_extensions/railtie' if defined?(Rails::Railtie)

# UnaryOperation|Grouping|Extract < Unary < Arel::Nodes::Node
# Equality|Regexp|Matches < Binary < Arel::Nodes::Node
# Count|NamedFunction < Function < Arel::Nodes::Node

# pure Arel internals improvements
class Arel::Nodes::Binary
  include Arel::AliasPredication
  include Arel::Expressions
end

class Arel::Nodes::Casted
  include Arel::AliasPredication

  # They forget to define hash.
  def hash
    [self.class, self.val, self.attribute].hash
  end
end

class Arel::Nodes::Unary
  include Arel::Math
  include Arel::AliasPredication
  include Arel::Expressions
end

class Arel::Nodes::Grouping
  include Arel::Math
  include Arel::AliasPredication
  include Arel::OrderPredications
  include Arel::Expressions
end

class Arel::Nodes::Function
  include Arel::Math
  include Arel::Expressions
end

if Arel::VERSION >= "7.1.0"
  class Arel::Nodes::Case
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
require 'arel_extensions/nodes/case'
require 'arel_extensions/nodes/soundex'
require 'arel_extensions/nodes/cast'
require 'arel_extensions/nodes/json'



module Arel
  def self.rand
    ArelExtensions::Nodes::Rand.new
  end

  def self.shorten s
    Base64.urlsafe_encode64(Digest::MD5.new.digest(s)).tr('=', '').tr('-', '_')
  end

  def self.json *expr
    if expr.length == 1
      ArelExtensions::Nodes::Json.new(expr.first)
    else
      ArelExtensions::Nodes::Json.new(expr)
    end
  end

  def self.when condition
    ArelExtensions::Nodes::Case.new.when(condition)
  end

  def self.duration s, expr
    ArelExtensions::Nodes::Duration.new(s.to_s+'i',expr)
  end

  def self.true
    Arel::Nodes::Equality.new(1,1)
  end

  def self.false
    Arel::Nodes::Equality.new(1,0)
  end

  def self.tuple *v
    Arel::Nodes::Grouping.new(v)
  end
end

class Arel::Attributes::Attribute
  include Arel::Math
  include ArelExtensions::Attributes
end

class Arel::Nodes::Function
  include ArelExtensions::Math
  include ArelExtensions::Comparators
  include ArelExtensions::DateDuration
  include ArelExtensions::MathFunctions
  include ArelExtensions::StringFunctions
  include ArelExtensions::BooleanFunctions
  include ArelExtensions::NullFunctions
  include ArelExtensions::Predications

  alias_method :old_as, :as
  def as other
    Arel::Nodes::As.new(self, Arel.sql(other))
  end
end

class Arel::Nodes::Unary
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::Predications
end

class Arel::Nodes::Grouping
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators

#  include ArelExtensions::Predications

  def when right, expression = nil
    ArelExtensions::Nodes::Case.new(self).when(right,expression)
  end

  def matches(other, escape = nil,case_sensitive = nil)
    if Arel::VERSION.to_i < 7
      Arel::Nodes::Matches.new(self, Arel::Nodes.build_quoted(other), escape)
    else
      Arel::Nodes::Matches.new(self, Arel::Nodes.build_quoted(other), escape, case_sensitive)
    end
  end

  def imatches(other, escape = nil)
    ArelExtensions::Nodes::IMatches.new(self, other, escape)
  end

  def cast right
    ArelExtensions::Nodes::Cast.new([self,right])
  end

  def in *other #In should handle nil element in the Array
    other = other.first if other.length <= 1
    case other
    when nil
      self.is_null
    when Arel::Nodes::Grouping
      Arel::Nodes::In.new(self, quoted_node(other))
    when Range
      self.between(other)
    when Arel::SelectManager
      Arel::Nodes::In.new(self, other.ast)
    when Enumerable
      nils, values   = other.partition{ |v| v.nil? }
      ranges, values = values.partition{ |v| v.is_a?(Range) || v.is_a?(Arel::SelectManager)}
      # In order of (imagined) decreasing efficiency: nil, values, and then more complex.
      clauses =
        nils.uniq.map { |r| self.in(r) } \
        + (case values.uniq.size
            when 0 then []
            when 1 then [self.in(values[0])]
            else [Arel::Nodes::In.new(self, quoted_array(values))] end) \
        + ranges.uniq.map { |r| self.in(r) }
      Arel::Nodes::Or.new clauses
    else
      Arel::Nodes::In.new(self, quoted_node(other))
    end
  end

  def not_in *other #In should handle nil element in the Array
    other = other.first if other.size == 0 || other.size == 1
    case other
    when nil
      self.is_not_null
    when Arel::Nodes::Grouping
      Arel::Nodes::NotIn.new(self, quoted_node(other))
    when Range
      Arel::Nodes::Not.new(self.between(other))
    when Arel::SelectManager
      Arel::Nodes::NotIn.new(self, other.ast)
    when Enumerable
      nils, values   = other.partition{ |v| v.nil? }
      ranges, values = values.partition{ |v| v.is_a?(Range) || v.is_a?(Arel::SelectManager)}
      # In order of (imagined) decreasing efficiency: nil, values, and then more complex.
      clauses =
        nils.uniq.map { |r| self.not_in(r) } \
        + (case values.uniq.size
            when 0 then []
            when 1 then [self.not_in(values[0])]
            else [Arel::Nodes::NotIn.new(self, quoted_array(values))] end) \
        + ranges.uniq.map { |r| self.not_in(r) }
      Arel::Nodes::And.new clauses
    else
      Arel::Nodes::NotIn.new(self,quoted_node(other))
    end
  end

  def convert_to_node(object)
    case object
    when Arel::Attributes::Attribute, Arel::Nodes::Node, Integer
      object
    when DateTime
      Arel::Nodes.build_quoted(object, self)
    when Time
      Arel::Nodes.build_quoted(object.strftime('%H:%M:%S'), self)
    when String
      Arel::Nodes.build_quoted(object)
    when Date
      Arel::Nodes.build_quoted(object.to_s, self)
    when NilClass
      Arel.sql('NULL')
    when ActiveSupport::Duration
      object.to_i
    else
      raise(ArgumentError, "#{object.class} can not be converted to CONCAT arg")
    end
  end

end

class Arel::Nodes::Binary
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::BooleanFunctions
  include ArelExtensions::Predications
end

class Arel::Nodes::Equality
  include ArelExtensions::Comparators
  include ArelExtensions::DateDuration
  include ArelExtensions::MathFunctions
  include ArelExtensions::StringFunctions
end

class Arel::InsertManager
  include ArelExtensions::InsertManager
end

class Arel::SelectManager
  include ArelExtensions::SetFunctions
  include ArelExtensions::Nodes
end

class Arel::Nodes::As
  include ArelExtensions::Nodes
end

class Arel::Table
  alias_method :old_alias, :alias
  def alias(name = "#{self.name}_2")
    name.blank? ? self : Arel::Nodes::TableAlias.new(self,name)
  end
end
