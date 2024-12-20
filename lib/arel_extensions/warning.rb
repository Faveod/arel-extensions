module ArelExtensions
  def self.deprecator
    return @deprecator if @deprecator

    version = Gem::Version.create(ArelExtensions::VERSION).segments
    version = "#{version[0]}.#{version[1]}"
    @deprecator = ActiveSupport::Deprecation.new(version, 'arel_extensions')
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
