require 'rubygems'
require 'minitest/autorun'
require 'fileutils'
require 'arel'
require 'active_record'

require 'support/fake_record'

def colored(color, msg)
  ENV["TERM"] =~ /^xterm|-256color$/ ? "\x1b[#{color}m#{msg}\x1b[89m\x1b[0m"  : "#{msg}"
end

YELLOW = "33"

def warn(msg)
  $stderr.puts(colored(YELLOW, msg))
end

# Load gems specific to databases
# NOTE: It's strongly advised to test each database on its own.
#       Loading multiple backend gems leads to undefined behavior according to
#       tests; the backend might not recognize the correct DB visitor and will
#       fallback to `ToSQL` and screw all tests.
db_and_gem =  if RUBY_ENGINE == 'jruby'
                {
                  'mysql'      => 'activerecord-jdbcmysql-adapter',
                  'postgresql' => 'activerecord-jdbcpostgresql-adapter',
                  'sqlite'     => 'activerecord-jdbcsqlite3-adapter',
                  'ibm_db'     => 'ibm_db',
                  'oracle'     => 'activerecord-oracle_enhanced-adapter',
                  'mssql'      => 'activerecord-jdbcsqlserver-adapter'
                }
              else
                {
                  'mysql'      => 'mysql2',
                  'postgresql' => 'pg',
                  'sqlite'     => 'sqlite3',
                  'ibm_db'     => 'ibm_db',
                  'oracle'     => 'activerecord-oracle_enhanced-adapter',
                  'mssql'      => 'activerecord-sqlserver-adapter'
                }
              end

def load_lib(gem)
  begin
    Gem::Specification.find_by_name(gem)
    require gem
  rescue Gem::MissingSpecError
    warn "Warning: failed to load gem #{gem}. Are you sure it's installed?"
  end
end

load_lib(db_and_gem[ENV['DB']]) if ENV['DB']&.strip&.empty?

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
