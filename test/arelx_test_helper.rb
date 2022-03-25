require 'rubygems'
require 'minitest/autorun'
require 'fileutils'
require 'arel'
require 'active_record'

require 'support/fake_record'

def colored(color, msg)
  /^xterm|-256color$/.match?(ENV['TERM']) ? "\x1b[#{color}m#{msg}\x1b[89m\x1b[0m" : "#{msg}"
end

YELLOW = '33'

def warn(msg)
  $stderr.puts(colored(YELLOW, msg))
end

# Load gems specific to databases
# NOTE:
#     It's strongly advised to test each database on its own. Loading multiple
#     backend gems leads to undefined behavior according to tests; the backend
#     might not recognize the correct DB visitor and will fallback to `ToSQL`
#     and screw all tests.
#
#     The issue also seems to be related to arel version: at some point, arel
#     dropped its wide support for DBs and kept Postgres, MySQL and SQLite.
#     Here, we're just trying to load the correct ones.
db_and_gem =
  if RUBY_ENGINE == 'jruby'
    {
      'oracle'     => 'activerecord-oracle_enhanced-adapter',
      'mssql'      => 'activerecord-jdbcsqlserver-adapter'
    }
  else
    {
      'oracle'     => 'activerecord-oracle_enhanced-adapter',
      'mssql'      => 'activerecord-sqlserver-adapter'
    }
  end

def load_lib(gem)
  if gem && (RUBY_ENGINE == 'jruby' || Arel::VERSION.to_i > 9)
    begin
      Gem::Specification.find_by_name(gem)
      require gem
    rescue Gem::MissingSpecError
      warn "Warning: failed to load gem #{gem}. Are you sure it's installed?"
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
