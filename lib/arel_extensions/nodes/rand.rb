module ArelExtensions
  module Nodes
    class Rand < Function
      RETURN_TYPE = :number

      def initialize(seed = nil)
        if seed && seed.length == 1
          super seed
        else
          super []
        end
      end
    end
  end
end
