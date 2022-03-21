require 'strscan'

module ArelExtensions
  module Nodes
    class Format < Function
      RETURN_TYPE = :string

      attr_accessor :col_type, :iso_format, :time_zone

      def initialize expr
        col = expr[0]
        @iso_format = convert_format(expr[1])
        @time_zone  = expr[2]
        @col_type = type_of_attribute(col)
        super [col, convert_to_string_node(@iso_format)]
      end

      private

      # Address portability issues with some of the formats.
      def convert_format(fmt)
        s = StringScanner.new fmt
        res = StringIO.new
        while !s.eos?
          res <<
            case
            when s.scan(/%D/)    then '%m/%d/%y'
            when s.scan(/%F/)    then '%Y-%m-%d'
            when s.scan(/%R/)    then '%H:%M'
            when s.scan(/%r/)    then '%I:%M:%S %p'
            when s.scan(/%T/)    then '%H:%M:%S'
            when s.scan(/%v/)    then '%e-%b-%Y'

            when s.scan(/[^%]+/) then s.matched
            when s.scan(/./)     then s.matched
            end
        end
        res.string
      end
    end
  end
end
