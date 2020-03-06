module ArelExtensions
  module Nodes
    class Std < Function
      RETURN_TYPE = :number

    class Std < AggregateFunction
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize node, opts = {}
        @unbiased_estimator = opts[:unbiased] ? true : false
        super node, opts
      end

    end

    class Variance < Function
      RETURN_TYPE = :number
      attr_accessor :unbiased_estimator

      def initialize node, opts = {}
        @unbiased_estimator = opts[:unbiased] ? true : false
        super node, opts
      end

    end

  end
end
