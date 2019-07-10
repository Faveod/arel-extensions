require 'arel_extensions/boolean_functions'

module ArelExtensions
  module Nodes
    class Blank < Arel::Nodes::Unary
      include ArelExtensions::BooleanFunctions
      RETURN_TYPE = :boolean

      def initialize expr
        super expr.first
      end
    end

    class NotBlank < Arel::Nodes::Unary
      include ArelExtensions::BooleanFunctions
      RETURN_TYPE = :boolean

      def initialize expr
          super expr.first
      end
    end

  end
end
