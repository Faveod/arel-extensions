module ArelExtensions
  module Predications
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

    def in(other) #In should handle nil element in the Array
      case other
      when Range
        self.between(other)
      when Enumerable
        if other.include?(nil)
          other.delete(nil)
          case other.length
          when 0
            self.is_null
          when 1
            self.is_null.or(self==other[0])
          else
            self.is_null.or(Arel::Nodes::In.new(self,quoted_array(other)))
          end
        else
          Arel::Nodes::In.new(self,quoted_array(other))
        end
      when nil
        self.is_null
      when Arel::SelectManager
        Arel::Nodes::In.new(self, other.ast)
      else
        Arel::Nodes::In.new(self,quoted_node(other))
      end
    end

    def not_in(other) #In should handle nil element in the Array
      case other
      when Range
        Arel::Nodes::Not.new(self.between(other))
      when Enumerable
        if other.include?(nil)
          other.delete(nil)
          case other.length
          when 0
            self.is_not_null
          when 1
            self.is_not_null.and(self!=other[0])
          else
            self.is_not_null.and(Arel::Nodes::NotIn.new(self,quoted_array(other)))
          end
        else
          Arel::Nodes::NotIn.new(self,quoted_array(other))
        end
      when nil
        self.is_not_null
      when Arel::SelectManager
        Arel::Nodes::NotIn.new(self, other.ast)
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
end
