module ArelExtensions
  module Nodes
    class Json < Node
      RETURN_TYPE = :json
      
      attr_accessor :hash

      def return_type
        self.class.const_get(:RETURN_TYPE)
      end

      def initialize *expr
        if expr.one?
          case expr.first
          when Array
            @hash = expr.first.map{|e| Json.new(e)}
          when Hash
            @hash = expr.first.inject({}){|acc,v|
              acc[convert_to_node(v[0])] = Json.new(v[1])
              acc
            }
          when Arel::Nodes::Node, Arel::Attributes::Attribute
            if [:json,:string].include?(expr.first.return_type)
              @hash = expr.first
            else
              @hash = expr.first.cast(:string)
            end
          else
            @hash = convert_to_node(expr.first)
          end
        end
      else
        @hash = expr.map{|e| Json.new(e)}
      end

    end
  end
end
