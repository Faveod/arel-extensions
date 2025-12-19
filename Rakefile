require 'bundler'
Bundler::GemHelper.install_tasks name: 'arel_extensions'

require 'rake/testtask'

desc 'Default Task'
task default: [:test]

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.warning = true
  t.verbose = true
end

namespace :test do
  Rake::TestTask.new('to_sql' => []) { |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/visitors/test_to_sql.rb'
    t.warning = true
    t.verbose = true
    t.ruby_opts = ['--dev'] if defined?(JRUBY_VERSION)
  }
end

%w[ibm_db mssql mysql oracle postgresql sqlite trilogy].each do |adapter|
  namespace :test do
    Rake::TestTask.new(adapter => "#{adapter}:env") { |t|
      t.libs << 'lib'
      t.libs << 'test'
      t.pattern = 'test/with_ar/*_agnostic_test.rb'
      t.warning = false
      t.verbose = true
      t.ruby_opts = ['--dev'] if defined?(JRUBY_VERSION)
    }
  end

  namespace adapter do
    task test: "test_#{adapter}"
    task isolated_test: "isolated_test_#{adapter}"

    # Set the connection environment for the adapter
    task(:env) { ENV['DB'] = adapter }
  end

  # Make sure the adapter test evaluates the env setting task
  task "test_#{adapter}" => ["#{adapter}:env", "test:#{adapter}"]
end

# Useful shorthands.
namespace :test do
  task :sql => :to_sql
  task :pg => :postgresql
  task :postgres => :postgresql
end
