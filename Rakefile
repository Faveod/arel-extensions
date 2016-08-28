require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc "Default Task"
task default: [ :test ]

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end
