module ArelExtensions
  module Nodes
    class Std < AggregateFunction
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize node, unbiased = true, opts = {}
        @unbiased_estimator = unbiased
        super node, opts
      end
    end

    class Variance < AggregateFunction
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize node, unbiased = true, opts = {}
        @unbiased_estimator = unbiased
        super node, opts
      end
    end

  end
end
