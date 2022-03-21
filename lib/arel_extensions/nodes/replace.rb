module ArelExtensions
  module Nodes
    class Replace < Function
      RETURN_TYPE = :string
      attr_accessor :left, :pattern, :substitute

      def initialize left, pattern, substitute
        @left = convert_to_node(left)
        @pattern = convert_to_node(pattern)
        @substitute = convert_to_node(substitute)
        super([@left,@pattern,@substitute])
      end
    end

    class RegexpReplace < Function
      RETURN_TYPE = :string
      attr_accessor :left, :pattern, :substitute

      def initialize left, pattern, substitute
        @left = convert_to_node(left)
        @pattern = (pattern.is_a?(Regexp) ? pattern : %r[#{pattern}])
        @substitute = convert_to_node(substitute)
        super([@left,@pattern,@substitute])
      end
    end
  end
end
