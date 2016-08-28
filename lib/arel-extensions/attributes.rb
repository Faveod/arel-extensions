require 'arel-extensions/comparators'
require 'arel-extensions/date_duration'
require 'arel-extensions/math'
require 'arel-extensions/math_functions'
require 'arel-extensions/null_functions'
require 'arel-extensions/string_functions'

module ArelExtensions
  module Attributes
	include ArelExtensions::Comparators
	include ArelExtensions::DateDuration
	include ArelExtensions::Math
	include ArelExtensions::MathFunctions
	include ArelExtensions::NullFunctions
	include ArelExtensions::StringFunctions

  	def ==(other)
      Arel::Nodes::Equality.new self, Arel::Nodes.build_quoted(other, self)
  	end

    def !=(other)
      Arel::Nodes::NotEqual.new self, Arel::Nodes.build_quoted(other, self)
    end

  end
end