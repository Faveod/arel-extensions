module ArelExtensions
  module Nodes
    class Std < AggregateFunction
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize(node, **opts)
        @unbiased_estimator = opts[:unbiased] ? true : false
        super
      end
    end

    class Variance < AggregateFunction
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize(node, **opts)
        @unbiased_estimator = opts[:unbiased] ? true : false
        super
      end
    end
  end
end
