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
  if Gem::Version.new(Arel::VERSION) < Gem::Version.new("10.0.0")
    def hash
      [self.class, self.val, self.attribute].hash
    end
  end
end

class Arel::Nodes::Unary
  include Arel::Math
  include Arel::AliasPredication
  include Arel::Expressions
end

class Arel::Nodes::Grouping
  include Arel::OrderPredications
end

class Arel::Nodes::Ordering
  def eql? other
    self.hash.eql? other.hash
  end
end

class Arel::Nodes::Function
  include Arel::Math
  include Arel::Expressions
end

if Gem::Version.new(Arel::VERSION) >= Gem::Version.new("7.1.0")
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
    ArelExtensions::Nodes::Json.new(
      if expr.length == 1
        expr.first
      else
        expr
      end
    )
  end

  def self.when condition
    ArelExtensions::Nodes::Case.new.when(condition)
  end

  def self.duration s, expr
    ArelExtensions::Nodes::Duration.new("#{s}i", expr)
  end

  def self.grouping *v
    Arel::Nodes::Grouping.new(*v)
  end

  # The TRUE pseudo literal.
  def self.true
    Arel::Nodes::Equality.new(1, 1)
  end

  # The FALSE pseudo literal.
  def self.false
    Arel::Nodes::Equality.new(1, 0)
  end

  # The NULL literal.
  def self.null
    Arel::Nodes.build_quoted(nil)
  end

  def self.tuple *v
    tmp = Arel.grouping(nil)
    Arel.grouping v.map{|e| tmp.convert_to_node(e)}
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

  alias_method(:old_as, :as) rescue nil
  def as other
    res = Arel::Nodes::As.new(self.clone, Arel.sql(other))
    if Gem::Version.new(Arel::VERSION) >= Gem::Version.new("9.0.0")
      self.alias = Arel.sql(other)
    end
    res
  end

  # Install an alias, if present.
  def xas other
    if other.present?
      Arel::Nodes::As.new(self, Arel.sql(other))
    else
      self
    end
  end

end

class Arel::Nodes::Grouping
    include ArelExtensions::Math
    include ArelExtensions::Comparators
    include ArelExtensions::DateDuration
    include ArelExtensions::MathFunctions
    include ArelExtensions::NullFunctions
    include ArelExtensions::StringFunctions
    include ArelExtensions::Predications
end

class Arel::Nodes::Unary
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::Predications
  def eql? other
    hash == other.hash
  end
end

class Arel::Nodes::Binary
  include ArelExtensions::Math
  include ArelExtensions::Attributes
  include ArelExtensions::MathFunctions
  include ArelExtensions::Comparators
  include ArelExtensions::BooleanFunctions
  include ArelExtensions::Predications
  def eql? other
    hash == other.hash
  end
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

  def as table_name
    Arel::Nodes::TableAlias.new(self, table_name)
  end
end

class Arel::Nodes::As
  include ArelExtensions::Nodes
end

class Arel::Table
  alias_method(:old_alias, :alias) rescue nil
  def alias(name = "#{self.name}_2")
    if name.present?
      Arel::Nodes::TableAlias.new(self, name)
    else
      self
    end
  end
end

class Arel::Nodes::TableAlias
  def method_missing(*args)
    met = args.shift.to_sym
    if self.relation.respond_to?(met)
      self.relation.send(met,args)
    else
      super(met,*args)
    end
  end
end
