# frozen_string_literal: true

require 'arel_extensions/nodes'
require 'arel_extensions/nodes/function'
require 'arel_extensions/nodes/concat'
require 'arel_extensions/nodes/cast'

require 'arel_extensions/nodes/date_diff'
require 'arel_extensions/nodes/duration'
require 'arel_extensions/nodes/wday'
require 'arel_extensions/nodes/union'
require 'arel_extensions/nodes/union_all'

module ArelExtensions
  module Math
    # function + between
    # String and others (convert in string)  allows you to concatenate 2 or more strings together.
    # Date and integer adds or subtracts a specified time interval from a date.
    def +(other)
      case self
      when Arel::Nodes::Quoted
        concat(other)
      when Arel::Nodes::Grouping
        if expr.left.is_a?(String) || expr.right.is_a?(String)
          concat(other)
        else
          Arel.grouping(Arel::Nodes::Addition.new(self, other))
        end
      when ArelExtensions::Nodes::Function, ArelExtensions::Nodes::Case
        case return_type
        when :string, :text
          concat(other)
        when :integer, :decimal, :float, :number, :int
          Arel.grouping(Arel::Nodes::Addition.new(self, other))
        when :date, :datetime
          ArelExtensions::Nodes::DateAdd.new [self, other]
        else
          concat(other)
        end
      when Arel::Nodes::Function
        Arel.grouping(Arel::Nodes::Addition.new(self, other))
      else
        col =
          if is_a?(Arel::Attribute) && respond_to?(:type_caster) && able_to_type_cast?
            type_caster
          elsif respond_to?(:relation)
            Arel.column_of(relation.table_name, name.to_s)
          end
        if col
          arg = col.type
          if arg == :integer || !arg
            other = other.to_i if other.is_a?(String)
            Arel.grouping(Arel::Nodes::Addition.new(self, Arel.quoted(other)))
          elsif %i[decimal float].include?(arg)
            other = Arel.sql(other) if other.is_a?(String) # Arel should accept Float & BigDecimal!
            Arel.grouping(Arel::Nodes::Addition.new(self, Arel.quoted(other)))
          elsif %i[datetime date].include?(arg)
            ArelExtensions::Nodes::DateAdd.new [self, other]
          elsif %i[string text].include?(arg)
            concat(other)
          end
        else
          Arel.grouping(Arel::Nodes::Addition.new(self, Arel.quoted(other)))
        end
      end
    end

    # function returns the time between two dates
    # function returns the substraction between two ints
    def -(other)
      case self
      when Arel::Nodes::Grouping
        if expr.left.is_a?(Date) || expr.left.is_a?(DateTime)
          Arel.grouping(ArelExtensions::Nodes::DateSub.new([self, Arel.quoted(other)]))
        else
          Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
        end
      when ArelExtensions::Nodes::Function, ArelExtensions::Nodes::Case
        case return_type
        when :string, :text # ???
          Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other))) # ??
        when :integer, :decimal, :float, :number
          Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
        when :date, :datetime
          ArelExtensions::Nodes::DateSub.new [self, Arel.quoted(other)]
        else
          Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
        end
      when Arel::Nodes::Function
        Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
      else
        col =
          if is_a?(Arel::Attribute) && respond_to?(:type_caster) && able_to_type_cast?
            type_caster
          elsif respond_to?(:relation)
            Arel.column_of(relation.table_name, name.to_s)
          end
        if col
          arg = col.type
          if %i[date datetime].include?(arg)
            case other
            when Arel::Attributes::Attribute
              col2 =
                if other.is_a?(Arel::Attribute) && other.respond_to?(:type_caster) && other.able_to_type_cast?
                  other.type_caster
                elsif other.respond_to?(:relation)
                  Arel.column_of(other.relation.table_name, other.name.to_s)
                end
              if col2
                arg2 = col2.type
                if %i[date datetime].include?(arg2)
                  ArelExtensions::Nodes::DateDiff.new [self, other]
                else
                  ArelExtensions::Nodes::DateSub.new [self, other]
                end
              else
                ArelExtensions::Nodes::DateSub.new [self, other]
              end
            when Arel::Nodes::Node, DateTime, Time, String, Date
              ArelExtensions::Nodes::DateDiff.new [self, other]
            when ArelExtensions::Nodes::Duration, Integer
              ArelExtensions::Nodes::DateSub.new [self, other]
            else # ActiveSupport::Duration
              ArelExtensions::Nodes::DateAdd.new [self, -other]
            end
          else
            case other
            when Integer, Float, BigDecimal
              Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.sql(other.to_s)))
            when String
              Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.sql(other)))
            else
              Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
            end
          end
        else
          Arel.grouping(Arel::Nodes::Subtraction.new(self, Arel.quoted(other)))
        end
      end
    end
  end
end
