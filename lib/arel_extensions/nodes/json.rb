module ArelExtensions
  module Nodes
    class JsonNode < Function
      RETURN_TYPE = :json

      attr_accessor :dict

      def merge(*expr)
        args = [self] + expr.map { |e| Json.new(e) }
        JsonMerge.new(args)
      end

      def get(path)
        JsonGet.new(self, path)
      end

      def set(path, value)
        JsonSet.new(self, path, value)
      end

      def remove(*paths)
        JsonRemove.new(self, paths)
      end

      def group(as_array = true, orders = nil, distinct: false)
        if distinct
          JsonGroup.new(Arel::Nodes::NamedFunction.new('DISTINCT', [self]), as_array, orders)
        else
          JsonGroup.new(self, as_array, orders)
        end
      end

      def hash
        [@dict].hash
      end

      def convert_to_json_node(n)
        case n
        when JsonNode
          n.dict
        when Array
          n.map { |e|
            e.is_a?(Array) || e.is_a?(Hash) ? Json.new(e) : convert_to_json_node(e)
          }
        when Hash
          n.reduce({}) { |acc, v|
            acc[convert_to_json_node(v[0])] = v[1].is_a?(Array) || v[1].is_a?(Hash) ? Json.new(v[1]) : convert_to_json_node(v[1])
            acc
          }
        when String, Numeric, TrueClass, FalseClass
          convert_to_node(n)
        when Date
          convert_to_node(n.strftime('%Y-%m-%d'))
        when DateTime, Time
          convert_to_node(n.strftime('%Y-%m-%dT%H:%M:%S.%L%:z'))
        when NilClass
          Arel.null
        when Arel::SelectManager
          Arel.grouping(n)
        else
          convert_to_node(n)
        end
      end

      # A boolean literal, either bare (TrueClass/FalseClass) or wrapped in a Quoted node
      # (which is how `convert_to_node` represents one after construction).
      def boolean_literal?(v)
        v.is_a?(TrueClass) \
          || v.is_a?(FalseClass) \
          || (v.is_a?(Arel::Nodes::Quoted) && [true, false].include?(v.expr))
      end

      # A path is a member name, or an Array of names reaching into a nested document.
      def convert_to_json_path(path)
        (path.is_a?(Array) ? path : [path]).map { |segment| convert_to_node(segment) }
      end

      def type_of_node(v)
        if v.is_a?(Arel::Attributes::Attribute)
          type_of_attribute(v)
        elsif v.is_a?(Numeric)
          :numeric
        elsif boolean_literal?(v)
          :boolean
        elsif v.respond_to?(:return_type)
          v.return_type
        elsif v.nil?
          :nil
        else
          :string
        end
      end
    end

    class Json < JsonNode
      def initialize(*expr)
        @dict =
          if expr.length == 1
            convert_to_json_node(expr.first)
          else
            expr.map { |e| convert_to_json_node(e) }
          end
        super
      end
    end

    class JsonMerge < JsonNode
    end

    class JsonGroup < JsonNode
      attr_accessor :as_array, :orders

      def initialize(json, as_array = true, orders = nil)
        @dict = as_array ? json : json.dict
        @as_array = as_array
        if orders
          @orders = Array(orders)
        end
      end
    end

    class JsonGet < JsonNode
      attr_accessor :path

      def initialize(json, path)
        @dict = json
        @path = convert_to_json_path(path)
      end

      # The single segment of a one segment path, the whole path otherwise.
      def key
        @path.length == 1 ? @path.first : @path
      end
    end

    class JsonSet < JsonNode
      attr_accessor :path, :value

      def initialize(json, path, value)
        @dict = json
        @path = convert_to_json_path(path)
        @value = Json.new(value)
      end

      def key
        @path.length == 1 ? @path.first : @path
      end
    end

    class JsonRemove < JsonNode
      attr_accessor :paths

      def initialize(json, paths)
        @dict = json
        @paths = paths.map { |path| convert_to_json_path(path) }
      end
    end
  end
end
