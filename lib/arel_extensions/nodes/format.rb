module ArelExtensions
  module Nodes
    class Format < Function
      RETURN_TYPE = :string

      attr_accessor :col_type, :iso_format
      def initialize expr
        col = expr.first
        @iso_format = expr[1]
        @col_type = type_of_attribute(col)
        super [col, convert_to_string_node(@iso_format)]
      end
    end
  end
end
