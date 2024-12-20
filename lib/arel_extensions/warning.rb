module ArelExtensions
  if RUBY_VERSION.split('.')[0].to_i < 3
    class RubyDeprecator
      def warn msg
        Kernel.warn(msg)
      end
    end
  else
    class RubyDeprecator
      def warn msg
        Kernel.warn(msg, category: :deprecated)
      end
    end
  end

  def self.deprecator
    @deprecator ||=
      if defined?(ActiveSupport::Deprecation)
        major, minor = Gem::Version.create(ArelExtensions::VERSION).segments
        ActiveSupport::Deprecation.new("#{major}.#{minor}", 'arel_extensions')
      else
        RubyDeprecator::new
      end
  end

  module Warning
    def deprecated msg, what: nil
      kaller = caller(2..2).first
      return if kaller.include?('lib/arel_extensions') && ENV['AREL_EXTENSIONS_IN_TEST'] != '1'

      what = caller_locations(1, 1).first.label if what.nil?
      ArelExtensions.deprecator.warn "#{kaller}: `#{what}` is now deprecated. #{msg}"
    end
  end
end
