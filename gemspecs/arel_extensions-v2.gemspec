$:.push File.expand_path('../lib', __FILE__)
require 'arel_extensions/version'

Gem::Specification.new do |s|
  s.name        = 'arel_extensions'
  s.version     = ArelExtensions::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Yann Azoury', 'Félix Bellanger', 'Julien Delporte']
  s.email       = ['yann.azoury@faveod.com', 'felix.bellanger@faveod.com', 'julien.delporte@faveod.com']
  s.homepage    = 'https://github.com/Faveod/arel-extensions'
  s.description = 'Adds new features to Arel'
  s.summary     = 'Extending Arel'
  s.license     = 'MIT'

  s.rdoc_options = ['--main', 'README.md']
  s.extra_rdoc_files = ['MIT-LICENSE.txt', 'README.md', 'functions.html']

  # Manifest
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency('activerecord', '>= 6.0')

  s.add_development_dependency('minitest', '~> 5.9')
  s.add_development_dependency('rake', '~> 12.3.3')
end
