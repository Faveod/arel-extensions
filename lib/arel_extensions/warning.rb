module ArelExtensions
  module Warning
    def deprecated msg
      what = caller_locations(1, 1).first.label
      kaller = caller(2..2).first
      msg = "#{kaller}: arel_extensions: `#{what}` is now deprecated. #{msg}"
      if RUBY_VERSION.to_f >= 3.0
        warn msg, category: :deprecated
      else
        warn msg
      end
    end
  end
end
