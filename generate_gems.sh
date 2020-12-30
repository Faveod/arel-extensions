
gem uninstall arel_extensions

# VERSION ~> 1
cp ./version_v1.rb lib/arel_extensions/version.rb
gem build ./arel_extensions.gemspec

# VERSION ~> 2
cp ./version_v2.rb lib/arel_extensions/version.rb
mv ./arel_extensions.gemspec ./arel_extensions.gemspec.bck
cp ./gemspecs/arel_extensions-v2.gemspec ./arel_extensions.gemspec
gem build ./arel_extensions.gemspec
cp ./version_v1.rb lib/arel_extensions/version.rb
cp ./gemspecs/arel_extensions-v1.gemspec ./arel_extensions.gemspec
