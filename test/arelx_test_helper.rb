require 'active_record'
require 'arel'
require 'fileutils'
require 'minitest/autorun'
require 'rubygems'
require 'support/fake_record'

require_relative './config_loader'

ENV['AREL_EXTENSIONS_IN_TEST'] = '1' # Useful for deprecation warnings.

def colored(color, msg)
  /^xterm|-256color$/.match?(ENV['TERM']) ? "\x1b[#{color}m#{msg}\x1b[89m\x1b[0m" : "#{msg}"
end

YELLOW = '33'

# Load gems specific to databases.
#
# NOTE:
#     It's strongly advised to test each database on its own. Loading multiple
#     backend gems leads to undefined behavior according to tests; the backend
#     might not recognize the correct DB visitor and will fallback to `ToSQL`
#     and screw all tests.
#
#     The issue also seems to be related to arel version: at some point, arel
#     dropped its wide support for DBs and kept Postgres, MySQL and SQLite.
#     Here, we're just trying to load the correct ones.
#
# NOTE:
#     As of jruby 9.4 (and maybe 9.3, but I couldn't test it given the state of
#     the alt-adapter), we need to load jdbc/mssql manually.
db_and_gem =
  if RUBY_PLATFORM == 'java'
    {
      'oracle'     => ['activerecord-oracle_enhanced-adapter'],
      'mssql'      => ['jdbc/mssql', 'activerecord-jdbcsqlserver-adapter'],
    }
  else
    {
      'oracle'     => ['activerecord-oracle_enhanced-adapter'],
      'mssql'      => ['activerecord-sqlserver-adapter'],
    }
  end

module Warning
  ARELX_IGNORED = [
    'PG::Coder.new(hash)',
    'rb_check_safe_obj',       # ruby 3.0
    'rb_tainted_str_new',      # ruby 3.0
    'Using the last argument', # ruby < 3.0
  ].freeze

  def self.warn(message)
    return if ARELX_IGNORED.any? { |msg| message.include?(msg) }

    super
  end
end


def load_lib(gems)
  if gems && (RUBY_PLATFORM == 'java' || Arel::VERSION.to_i > 9)
    gems.each do |gem|
      begin
        require gem
      rescue Exception => e
        warn "Warning: failed to load gem #{gem}. Are you sure it's installed?"
        warn e.message
      end
    end
  end
end

load_lib(db_and_gem[ENV['DB']])

require 'arel_extensions'

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
