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
          return self.concat(other)
        when Arel::Nodes::Grouping
          if self.expr.left.is_a?(String) || self.expr.right.is_a?(String)
            return self.concat(other)
          else
            return Arel.grouping(Arel::Nodes::Addition.new self, other)
          end
        when ArelExtensions::Nodes::Function,ArelExtensions::Nodes::Case
          return case self.return_type
        when :string, :text
          self.concat(other)
        when :integer, :decimal, :float, :number, :int
          Arel.grouping(Arel::Nodes::Addition.new self, other)
        when :date, :datetime
          ArelExtensions::Nodes::DateAdd.new [self, other]
        else
          self.concat(other)
        end
      when Arel::Nodes::Function
        Arel.grouping(Arel::Nodes::Addition.new self, other)
      else
        begin
          col = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s]
        rescue Exception
          col = nil
        end
        if (!col) # if the column doesn't exist in the database
          Arel.grouping(Arel::Nodes::Addition.new(self, other))
        else
          arg = col.type
          if arg == :integer || (!arg)
            other = other.to_i if other.is_a?(String)
            Arel.grouping(Arel::Nodes::Addition.new self, other)
          elsif arg == :decimal || arg == :float
            other = Arel.sql(other) if other.is_a?(String) # Arel should accept Float & BigDecimal!
            Arel.grouping(Arel::Nodes::Addition.new self, other)
          elsif arg == :datetime || arg == :date
            ArelExtensions::Nodes::DateAdd.new [self, other]
          elsif arg == :string || arg == :text
            self.concat(other)
          end
        end
      end
    end

    # function returns the time between two dates
    # function returns the substraction between two ints
    def -(other)
      case self
      when Arel::Nodes::Grouping
        if self.expr.left.is_a?(Date) || self.expr.left.is_a?(DateTime)
          Arel.grouping(ArelExtensions::Nodes::DateSub.new [self, other])
        else
          Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
        end
      when ArelExtensions::Nodes::Function, ArelExtensions::Nodes::Case
        case self.return_type
        when :string, :text # ???
          Arel.grouping(Arel::Nodes::Subtraction.new(self, other)) # ??
        when :integer, :decimal, :float, :number
          Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
        when :date, :datetime
          ArelExtensions::Nodes::DateSub.new [self, other]
        else
          Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
        end
      when Arel::Nodes::Function
        Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
      else
        begin
          col = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s]
        rescue Exception
          col = nil
        end
        if (!col) # if the column doesn't exist in the database
          Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
        else
          arg = col.type
          if (arg == :date || arg == :datetime)
            case other
            when Arel::Attributes::Attribute
              begin
                col2 = Arel::Table.engine.connection.schema_cache.columns_hash(other.relation.table_name)[other.name.to_s]
              rescue Exception
                col2 = nil
              end
              if (!col2) # if the column doesn't exist in the database
                ArelExtensions::Nodes::DateSub.new [self, other]
              else
                arg2 = col2.type
                if arg2 == :date || arg2 == :datetime
                  ArelExtensions::Nodes::DateDiff.new [self, other]
                else
                  ArelExtensions::Nodes::DateSub.new [self, other]
                end
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
              Arel.grouping(Arel::Nodes::Subtraction.new(self, other))
            end
          end
        end
      end
    end
  end
end
