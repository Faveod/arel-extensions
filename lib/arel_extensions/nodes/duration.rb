module ArelExtensions
  module Nodes
    class Duration < Function
      RETURN_TYPE = :number

      attr_accessor :with_interval

      def initialize left, right, aliaz = nil
        tab = Array.new
        tab << left
        tab << right
        @with_interval = left.end_with?('i')
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
