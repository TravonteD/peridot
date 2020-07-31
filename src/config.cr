require "yaml"

struct Server
  include YAML::Serializable

  property host : String
  property port : Int32
end

struct Config
  include YAML::Serializable

  property keys : Hash(String, String)
  property colors : Hash(String, Int32)
  property server : Server
end

struct Peridot::Config
  def self.parse(config : String)
    ::Config.from_yaml(config)
  end
end
