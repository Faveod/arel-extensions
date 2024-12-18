module ArelExtensions
  module Warning
    def deprecated msg
      kaller = caller(2..2).first
      return if kaller.include?('lib/arel_extensions') && ENV['AREL_EXTENSIONS_IN_TEST'] != '1'

      what = caller_locations(1, 1).first.label
      msg = "#{kaller}: arel_extensions: `#{what}` is now deprecated. #{msg}"

      if RUBY_VERSION.to_f >= 3.0
        warn msg, category: :deprecated
      else
        warn msg
      end
    end
  end
end
