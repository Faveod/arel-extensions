module ArelExtensions
  module Nodes
    class Wday < Function


      def initialize other, aliaz = nil
        tab = Array.new
        tab << other
        super(tab, aliaz)
      end


      def date
        @expressions.first
      end

    end
  end
end
