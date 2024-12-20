module ArelExtensions
  class RubyDeprecator
    if RUBY_VERSION.split('.')[0].to_i < 3
      def warn msg
        Kernel.warn(msg)
      end
    else
      def warn msg
        Kernel.warn(msg, category: :deprecated)
      end
    end
  end

  # To configure deprecations in a Rails application, you can do something
  # like this:
  #
  # ```ruby
  #   ArelExtensions.deprecator.behavior =
  #     (Rails.application.config.active_support.deprecation || :stderr)
  # ```
  #
  # See ActiveSupport's deprecation documentation for more details.
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
