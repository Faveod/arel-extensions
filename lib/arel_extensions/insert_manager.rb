require 'arel'

module ArelExtensions
  module InsertManager
    def bulk_insert(cols, data)
      res_columns = []
      case cols.first
      when Array
        case cols.first.first
        when Arel::Attributes::Attribute
          res_columns = cols
        when String
          res_columns = cols.map {|c| [@ast.relation[c.first]] }
        end
      when NilClass
        res_columns = @ast.relation.columns
      when String, Symbol
        cols.each { |c|
          res_columns << @ast.relation[c]
        }
      end
      self.values = BulkValues.new(res_columns, data)
      @ast.columns = res_columns
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
