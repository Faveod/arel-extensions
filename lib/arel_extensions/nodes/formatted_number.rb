module ArelExtensions
  module Nodes
    class FormattedNumber < Function
      RETURN_TYPE = :string

      attr_accessor :locale, :prefix, :suffix, :flags, :scientific_notation, :width,:precision, :type, :original_string

      def initialize expr
        # expr[1] = {locale: 'fr_FR', type: "e"/"f"/"d", prefix: "$ ", suffix: " %", flags: " +-#0", width: 5, precision: 6}
        col = expr.first
        @locale = expr[1][:locale]
        @prefix = expr[1][:prefix]
        @suffix = expr[1][:suffix]
        @width = expr[1][:width]
        @precision = expr[1][:precision]
        @type = expr[1][:type]
        @flags = expr[1][:flags]
        @scientific_notation = /[eE]/.match(expr[1][:type]) || false
        @original_string = expr[1][:original_string]
        super [col]
      end
    end
  end
end
