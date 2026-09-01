module ArelExtensions
  module Nodes
    class Substring < Function
      RETURN_TYPE = :string

      def initialize(expr)
        start = expr[1]
        if start.is_a?(Range) && expr[2]
          raise ArgumentError, 'cannot pass a length together with a Range start; the Range already determines the extracted length'
        end

        tab = [convert_to_node(expr[0]), start.is_a?(Range) ? start : convert_to_node(start)]
        if expr[2]
          tab << convert_to_node(expr[2])
        end
        super(tab)
      end

      def range?
        expressions[1].is_a?(Range)
      end

      # Builds the vendor-agnostic Arel node tree reproducing Ruby's
      # `String#[Range]` semantics: endless/beginless ranges, negative
      # "from the end" indices, `exclude_end?`, and Ruby's `nil`-vs-`""`
      # distinction (out of range vs valid-but-empty).
      #
      # Only meaningful when `#range?` is true; visitors need to check
      # that first, then `visit` the node this returns.
      def range_substring_node
        col = expressions[0]
        range = expressions[1]
        b = range.begin
        e = range.end
        n = col.char_length

        b_idx =
          if b.nil?
            0
          elsif b.negative?
            n + b
          else
            b
          end

        e_idx =
          if e.nil?
            n
          else
            raw = e.negative? ? n + e : e
            range.exclude_end? ? raw : raw + 1
          end

        e_idx_clamped = Arel.when(n < e_idx).then(n).else(e_idx)

        cases = Arel.when(col.is_null).then(Arel.quoted(nil))
        cases = cases.when(n < b_idx).then(Arel.quoted(nil))
        cases = cases.when(b_idx < 0).then(Arel.quoted(nil)) if b.is_a?(Integer) && b.negative?
        cases
          .when(e_idx_clamped <= b_idx).then(Arel.quoted(''))
          .else(Substring.new([col, b_idx + 1, e_idx_clamped - b_idx]))
      end
    end
  end
end
