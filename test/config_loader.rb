require 'erb'
require 'yaml'

module ConfigLoader
  def self.load(path)
    yaml_content = ERB.new(File.read(path)).result
    YAML.load(yaml_content)
  end
end
