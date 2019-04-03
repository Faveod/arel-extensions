module ArelExtensions
  module Nodes
    class JsonNode < Function
      RETURN_TYPE = :json

      attr_accessor :hash

      def merge *expr
        args = [self] + expr.map{|e| Json.new(e)}
        JsonMerge.new(args)
      end

      def get key
        JsonGet.new(self,key)
      end

      def set key, value
        JsonSet.new(self,key,value)
      end

      def group as_array = true
        JsonGroup.new(self,as_array)
      end

    end

    class Json < JsonNode

      def initialize *expr
        if expr.length == 1
          case expr.first
          when JsonNode
            @hash = expr.first.hash
          when Array
            @hash = expr.first.map{|e|
              (e.is_a?(Array) || e.is_a?(Hash)) ? Json.new(e) : convert_to_node(e)
            }
          when Hash
            @hash = expr.first.inject({}){|acc,v|
              acc[convert_to_node(v[0])] =  (v[1].is_a?(Array) || v[1].is_a?(Hash)) ? Json.new(v[1]) :  convert_to_node(v[1])
              acc
            }
          when String, Numeric, TrueClass, FalseClass
            @hash = convert_to_node(expr.first)
          when NilClass
            @hash = Arel.sql('null')
          else
            if expr.first.is_a?(String) || (expr.first.is_a?(Arel::Attributes::Attribute) && type_of_attribute(expr.first) == :string) || (expr.first.return_type == :string)
              @hash = convert_to_node(expr.first)
            else
              @hash = [convert_to_node(expr.first)]
            end
          end
        else
          @hash = expr.map{|e| (e.is_a?(Array) || e.is_a?(Hash)) ? Json.new(e) : convert_to_node(e) }
        end
      end

    end

    class JsonMerge < JsonNode
    end

    class JsonGroup < JsonNode
      attr_accessor :as_array

      def initialize json, as_array = true
        @hash = as_array ? json : json.hash
        @as_array = as_array
      end
    end

    class JsonGet < JsonNode
      attr_accessor :key

      def initialize json, key
        @hash = json
        @key = convert_to_node(key)
      end

    end

    class JsonSet < JsonNode
      attr_accessor :key, :value

      def initialize json, key, value
        @hash = json
        @key = convert_to_node(key)
        @value = Json.new(value)
      end

    end

  end
end
