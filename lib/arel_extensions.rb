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
