# frozen_string_literal: true

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
    include ArelExtensions::Warning

    def ==(other)
      deprecated 'Use `.eq` instead.' if Gem::Version.create(ArelExtensions::VERSION) >= Gem::Version.create('2.2')
      Arel::Nodes::Equality.new self, Arel.quoted(other, self)
    end

    def !=(other)
      deprecated 'Use `.not_eq` instead.' if Gem::Version.create(ArelExtensions::VERSION) >= Gem::Version.create('2.2')
      Arel::Nodes::NotEqual.new self, Arel.quoted(other, self)
    end
  end
end
