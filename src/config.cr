require "yaml"

struct Peridot::Config
  def self.parse(config : String)
    data = YAML.parse(config)
  end
end
