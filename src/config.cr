require "yaml"

struct Config
  include YAML::Serializable

  property keys : Hash(String, String)
  property colors : Hash(String, Int32)
  property server : Hash(String, String | Int32)
end

struct Peridot::Config
  def self.parse(config : String)
    ::Config.from_yaml(config)
  end
end
