require 'arel_extensions/boolean_functions'

module ArelExtensions
  module Nodes
    class IsNull < Arel::Nodes::Unary
      include ArelExtensions::BooleanFunctions
      RETURN_TYPE = :boolean
    end

    class IsNotNull < Arel::Nodes::Unary
      include ArelExtensions::BooleanFunctions
      RETURN_TYPE = :boolean
    end
  end
end
