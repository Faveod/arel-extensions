# # -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
# require "arel-extensions"

Gem::Specification.new do |s|
  s.name        = "arel-extensions"
  s.version     = '0.8.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Yann Azoury", "Mathilde Pechdi", "Félix Bellanger"]
  s.email       = ["yann.azoury@faveod.com", "mathilde.pechdimaldjian@gmail.com", "felix.bellanger@faveod.com"]
  s.homepage    = "https://gitlab.com/keeguon/arel-extensions"
  s.description = "Adds new features to Arel"
  s.summary     = "Extending Arel"
  s.license     = %q{MIT}

  s.rdoc_options = ["--main", "README.md"]
  s.extra_rdoc_files = ["MIT-LICENSE.txt", "README.md"]

  # Manifest
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency('arel', '~> 6.0')

  s.add_development_dependency('minitest')
  s.add_development_dependency('rdoc', '~> 4.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('activesupport', '~> 4.0')
  s.add_development_dependency('activemodel', '~> 4.0')
  s.add_development_dependency('activerecord', '~> 4.0')
end
