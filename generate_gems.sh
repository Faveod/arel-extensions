
gem uninstall arel_extensions

# VERSION ~> 1
cp ./version_v1.rb lib/arel_extensions/version.rb
gem build ./arel_extensions.gemspec

# VERSION ~> 2
cp ./version_v2.rb lib/arel_extensions/version.rb
gem build ./gemspec_v2/arel_extensions-v2.gemspec
mv ./gemspec_v2/*.gem ./
cp ./version_v1.rb lib/arel_extensions/version.rb
