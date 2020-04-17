module ArelExtensions
  module Nodes
    class JsonNode < Function
      RETURN_TYPE = :json

      attr_accessor :dict

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

      def group as_array = true, orders = nil
        JsonGroup.new(self,as_array, orders)
      end

      def hash
        [@dict].hash
      end

    end

    class Json < JsonNode

      def initialize *expr
        @dict =
          if expr.length == 1
            case exp = expr.first
            when JsonNode
              exp.dict
            when Array
              exp.map{|e|
                (e.is_a?(Array) || e.is_a?(Hash)) ? Json.new(e) : convert_to_node(e)
              }
            when Hash
              exp.reduce({}){|acc,v|
                acc[convert_to_node(v[0])] = (v[1].is_a?(Array) || v[1].is_a?(Hash)) ? Json.new(v[1]) : convert_to_node(v[1])
                acc
              }
            when String, Numeric, TrueClass, FalseClass
              convert_to_node(exp)
            when NilClass
              Arel.sql('null')
            else
              if (exp.is_a?(Arel::Attributes::Attribute) && type_of_attribute(exp) == :string) \
                 || (exp.return_type == :string)
                convert_to_node(exp)
              else
                [convert_to_node(exp)]
              end
            end
          else
            expr.map{|e| (e.is_a?(Array) || e.is_a?(Hash)) ? Json.new(e) : convert_to_node(e) }
          end
        super
      end

    end

    class JsonMerge < JsonNode
    end

    class JsonGroup < JsonNode
      attr_accessor :as_array, :orders

      def initialize json, as_array = true, orders = nil
        @dict = as_array ? json : json.dict
        @as_array = as_array
        if orders
          @orders = Array(orders)
        end
      end
    end

    class JsonGet < JsonNode
      attr_accessor :key

      def initialize json, key
        @dict = json
        @key = convert_to_node(key)
      end

    end

    class JsonSet < JsonNode
      attr_accessor :key, :value

      def initialize json, key, value
        @dict = json
        @key = convert_to_node(key)
        @value = Json.new(value)
      end

    end

  end
end
