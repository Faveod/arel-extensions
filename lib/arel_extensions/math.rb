require 'arel_extensions/nodes'
require 'arel_extensions/nodes/concat'

require 'arel_extensions/nodes/date_diff'
require 'arel_extensions/nodes/duration'
require 'arel_extensions/nodes/wday'

module ArelExtensions
  module Math
    #function + between
    #String and others (convert in string)  allows you to concatenate 2 or more strings together.
    #Date and integer adds or subtracts a specified time interval from a date.
    def +(other)
      return ArelExtensions::Nodes::Concat.new [self, other] if self.is_a?(Arel::Nodes::Quoted)
      if self.is_a?(Arel::Nodes::Grouping)
        if self.expr.left.is_a?(String) || self.expr.right.is_a?(String)
          return ArelExtensions::Nodes::Concat.new [self, other]
        else
          return Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
        end
      end
      return case self.class.return_type
      when :string, :text
        ArelExtensions::Nodes::Concat.new [self, other]
      when :integer, :decimal, :float, :number
        Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
      when :date, :datetime
        ArelExtensions::Nodes::DateAdd.new [self, other]
      else
        ArelExtensions::Nodes::Concat.new [self, other]
      end if self.is_a?(ArelExtensions::Nodes::Function)
      arg = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
      if arg == :integer
        other = other.to_i if other.is_a?(String)
        Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
      elsif arg == :decimal || arg == :float
        other = Arel.sql(other) if other.is_a?(String)  # Arel should accept Float & BigDecimal!
        Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
      elsif arg == :datetime || arg == :date
        ArelExtensions::Nodes::DateAdd.new [self, other]
      elsif arg == :string || arg == :text
        ArelExtensions::Nodes::Concat.new [self, other]
      end        
    end

    #function returns the time between two dates
    #function returns the substraction between two ints
    def -(other)
      return case self.class.return_type
      when :string, :text # ???
        Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other)) # ??
      when :integer, :decimal, :float, :number
        Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
      when :date, :datetime
        ArelExtensions::Nodes::DateSub.new [self, other]
      else
        Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
      end if self.is_a?(ArelExtensions::Nodes::Function)
      arg = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
      if (arg == :date || arg == :datetime)
        case other
        when Arel::Attributes::Attribute
          arg2 = Arel::Table.engine.connection.schema_cache.columns_hash(other.relation.table_name)[other.name.to_s].type
          if arg2 == :date || arg2 == :datetime
            ArelExtensions::Nodes::DateDiff.new [self, other]
          else
            ArelExtensions::Nodes::DateSub.new [self, other]
          end
        when Arel::Nodes::Node, DateTime, Time, String, Date
          ArelExtensions::Nodes::DateDiff.new [self, other]
        when Integer
          ArelExtensions::Nodes::DateSub.new [self, other]
        end
      else
        case other
        when Integer, Float, BigDecimal
          Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, Arel.sql(other.to_s)))
        when String
          Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, Arel.sql(other)))
        else
          Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
        end
      end
    end

  end
end
