source "https://rubygems.org"

gemspec

group :development, :test do
  gem "sqlite3", :platforms => [:mri]
  gem "mysql2",  :platforms => [:mri]
  gem "pg", :platforms => [:mri]

  gem "jdbc-sqlite3", :platforms => :jruby
  gem "activerecord-jdbcsqlite3-adapter", :platforms => :jruby
  gem "activerecord-jdbcmysql-adapter", :platforms => :jruby
  gem "activerecord-jdbcpostgresql-adapter", :platforms => :jruby

  gem "tiny_tds", '~> 1.3.0' ,:require => false, :platforms => [:mingw, :x64_mingw, :mswin]
  gem "activerecord-sqlserver-adapter", '~> 4.2.0', :platforms => [:mingw, :x64_mingw, :mswin]
  
  gem 'ruby-oci8', :platforms => [:mri] 
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0', :platforms => [:mri]

  gem 'activesupport', '~> 4.0'
  gem 'activemodel', '~> 4.0'
  gem 'activerecord', '~> 4.0'
end
