require 'arel'

module ArelExtensions
  module InsertManager

    def bulk_insert(cols, data)
    res_columns = []
      case cols.first
      when String, Symbol
        cols.each { |c|
          res_columns << @ast.relation[c]
        }
      when Array
        if String === cols.first.first
          res_columns = cols.map {|c| [@ast.relation[c.first]] }
        elsif Arel::Attributes::Attribute == cols.first.first
          res_columns = cols
        end
      when NilClass
        res_columns = @ast.relation.columns
      end
      if defined?(Arel::Nodes::ValuesList)
        self.values = Arel::Nodes::ValuesList.new(data)
        res_columns.each do |col|
          self.columns << col
        end
      else
        self.values = BulkValues.new(res_columns, data)
        @ast.columns = res_columns
      end
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
