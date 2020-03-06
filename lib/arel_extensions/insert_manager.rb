require 'arel'

module ArelExtensions
  module InsertManager

    def bulk_insert(cols, data)
      case cols.first
      when String, Symbol
        cols.each { |c|
          @ast.columns << @ast.relation[c]
        }
      when Array
        if String === cols.first.first
          @ast.columns = cols.map {|c| [@ast.relation[c.first]] }
        elsif Arel::Attributes::Attribute == cols.first.first
          @ast.columns = cols
        end
      when NilClass
        @ast.columns = @ast.relation.columns
      end
      self.values = BulkValues.new(@ast.columns, data)
    end

    class BulkValues < Arel::Nodes::Node
      attr_accessor :left, :cols
      def initialize(cols, values)
        @left = values
        @cols = cols
      end
    end

  end
end
