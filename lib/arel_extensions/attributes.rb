require 'arel_extensions/aliases'
require 'arel_extensions/math'
require 'arel_extensions/comparators'
require 'arel_extensions/date_duration'
require 'arel_extensions/math_functions'
require 'arel_extensions/null_functions'
require 'arel_extensions/string_functions'
require 'arel_extensions/predications'

module ArelExtensions
  module Attributes
    include ArelExtensions::Aliases
    include ArelExtensions::Math
    include ArelExtensions::Comparators
    include ArelExtensions::DateDuration
    include ArelExtensions::MathFunctions
    include ArelExtensions::NullFunctions
    include ArelExtensions::StringFunctions
    include ArelExtensions::Predications

    @@warn_eqeq = true
    @@warn_noteq = true

    def ==(other)
      if Gem::Version.create(ArelExtensions::VERSION) >= Gem::Version.create('2.2') && @@warn_eqeq
        warn("#{caller(1..1).first} arel_extensions: `==` is now deprecated and will be removed soon. Use `.eq` instead.")
        @@warn_eqeq = false
      end
      Arel::Nodes::Equality.new self, Arel.quoted(other, self)
    end

    def !=(other)
      if Gem::Version.create(ArelExtensions::VERSION) >= Gem::Version.create('2.2') && @@warn_noteq
        warn("#{caller(1..1).first} arel_extensions: `!=` is now deprecated and will be removed soon. Use `.not_eq` instead.")
        @@warn_noteq = false
      end
      Arel::Nodes::NotEqual.new self, Arel.quoted(other, self)
    end
  end
end
