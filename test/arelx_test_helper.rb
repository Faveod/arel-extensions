require 'rubygems'
require 'minitest/autorun'
require 'fileutils'
require 'arel'
require 'active_record'

require 'support/fake_record'

require 'arel_extensions'
Arel::Table.engine = FakeRecord::Base.new

$arel_silence_type_casting_deprecation = true

module Minitest::Assertions
  #
  #  Fails unless +expected and +actual are the same string, modulo extraneous spaces.
  #
  def assert_like(expected, actual, msg = nil)
    msg ||= "Expected #{expected.inspect} and #{actual.inspect} to be alike"
    assert_equal expected.gsub(/\s+/, ' ').strip, actual.gsub(/\s+/, ' ').strip
  end
end

module Minitest::Expectations

  infect_an_assertion :assert_like, :must_be_like

end
