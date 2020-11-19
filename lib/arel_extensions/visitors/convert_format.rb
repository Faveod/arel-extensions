module ArelExtensions
  module Visitors
    # Convert date format in strftime syntax to whatever the RDBMs
    # wants, based on the table of conversion +mapping+.
    def self.strftime_to_format format, mapping
      @mapping_regexps ||= {}
      @mapping_regexps[mapping] ||=
        Regexp.new(
          mapping
            .keys
            .map{|k| Regexp.escape(k)}
            .join('|')
        )

      regexp = @mapping_regexps[mapping]
      s = StringScanner.new format
      res = StringIO.new
      while !s.eos?
        res <<
          case
          when s.scan(regexp)
            if v = mapping[s.matched]
              v
            else
              # Should never happen.
              s.matched
            end
          when s.scan(/[^%]+/)
            s.matched
          when s.scan(/./)
            s.matched
          end
      end
      res.string
    end
  end
end
