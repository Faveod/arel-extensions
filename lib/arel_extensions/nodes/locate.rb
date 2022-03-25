module ArelExtensions
  module Nodes
    class Locate < Function
      RETURN_TYPE = :integer

      def initialize expr
        tab = expr.map do |arg|
          convert_to_node(arg)
        end
        super(tab)
      end
    end
  end
end
