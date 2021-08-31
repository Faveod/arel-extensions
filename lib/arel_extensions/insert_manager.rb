require 'arel'

module ArelExtensions
  module InsertManager
    def bulk_insert(cols, data)
      raise ArgumentError, "cols must be present" if cols.blank?
      columns =
        case cols.first
        when Array
          case cols.first.first
          when Arel::Attributes::Attribute
            cols
          when String, Symbol
            cols.map {|c| [@ast.relation[c.first]] }
          else
            raise ArgumentError, "cols has an invalid type: #{cols.first.first.class}"
          end
        when String, Symbol
          cols.map { |c| @ast.relation[c] }
        else
          raise ArgumentError, "cols has an invalid type: #{cols.first.class}"
        end
      self.values = BulkValues.new(columns, data)
      @ast.columns = columns
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
