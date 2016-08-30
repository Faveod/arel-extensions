module ArelExtensions
    module Math
      #function + between
     #String and others (convert in string)  allows you to concatenate 2 or more strings together.
     #Date and integer adds or subtracts a specified time interval from a date.
      def +(other)
        return ArelExtensions::Nodes::Concat.new(self.expressions + [other]) if self.is_a?(ArelExtensions::Nodes::Concat)
        arg = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
        if arg == :integer || arg == :decimal || arg == :float
          if other.is_a?(String)
            other = other.to_i
          end
          Arel::Nodes::Grouping.new(Arel::Nodes::Addition.new self, other)
        elsif arg == :datetime || arg == :date
          ArelExtensions::Nodes::DateAdd.new [self, other]
        elsif arg == :string
          ArelExtensions::Nodes::Concat.new [self, other]
        end        
      end

      #function returns the time between two dates
      #function returns the susbration between two int
      def -(other)
        arg = Arel::Table.engine.connection.schema_cache.columns_hash(self.relation.table_name)[self.name.to_s].type
        if (arg == :date || arg == :datetime)
          case other
          when Arel::Attributes::Attribute
            arg2 = Arel::Table.engine.connection.schema_cache.columns_hash(other.relation.table_name)[other.name.to_s].type
            if arg2 == :date || arg2 == :datetime
              ArelExtensions::Nodes::DateDiff.new self, other
            else
              ArelExtensions::Nodes::DateSub.new self, other
            end
          when Arel::Nodes::Node, DateTime, Time, String, Date
            ArelExtensions::Nodes::DateDiff.new self, other
          when Fixnum
            ArelExtensions::Nodes::DateSub.new self, other
          end
        else
          if other.is_a?(String)
            other = other.to_i
          end
          Arel::Nodes::Grouping.new(Arel::Nodes::Subtraction.new(self, other))
        end
      end

    end
end
