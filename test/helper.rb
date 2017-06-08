require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'minitest/autorun'
require 'fileutils'
require 'arel'
require 'active_record'

require 'arel_extensions'

require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

$arel_silence_type_casting_deprecation = true

class Object
  def must_be_like other
    gsub(/\s+/, ' ').strip.must_equal other.gsub(/\s+/, ' ').strip
  end
end