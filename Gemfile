source "https://rubygems.org"

gemspec

group :development, :test do
  gem "sqlite3", '<= 1.3.13', platforms: [:mri]
  gem "mysql2", '0.4.10', platforms: [:mri]
  gem "pg", '< 1', platforms: [:mri]

  gem "jdbc-sqlite3", platforms: :jruby
  gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby
  gem "activerecord-jdbcmysql-adapter", platforms: :jruby
  gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby

  gem "tiny_tds", '~> 2.1', require: false, platforms: [:mri, :mingw, :x64_mingw, :mswin]
  gem "activerecord-sqlserver-adapter", '~> 6.0', platforms: [:mri, :mingw, :x64_mingw, :mswin]

  gem 'ruby-oci8', platforms: [:mri, :mswin, :x64_mingw, :mingw]
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0'

  gem 'activesupport', '~> 6.0'
  gem 'activemodel', '~> 6.0'
  gem 'activerecord', '~> 6.0'
end
