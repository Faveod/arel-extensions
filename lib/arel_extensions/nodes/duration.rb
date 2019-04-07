module ArelExtensions
  module Nodes
    class Duration < Function
      RETURN_TYPE = :number

      def initialize left, right, aliaz = nil
        tab = Array.new
        tab << left
        tab << right
        super(tab, aliaz)
      end


      def left
        @expressions.first
      end


      def right
        @expressions[1]
      end

    end
  end
end
