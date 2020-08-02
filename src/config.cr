require "yaml"

struct Server
  include YAML::Serializable

  property host : String
  property port : Int32
end

struct Keybinding::Format
  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Hash(String, String)
    result = {} of String => String
    node.as(YAML::Nodes::Mapping).each do |k, v|
      result[v.as(YAML::Nodes::Scalar).value] = k.as(YAML::Nodes::Scalar).value
    end
    result
  end
end

struct Config
  include YAML::Serializable

  @[YAML::Field(converter: Keybinding::Format)]
  property keys : Hash(String, String)
  property colors : Hash(String, Int32)
  property server : Server
end

struct Peridot::Config
  def self.parse(config : String)
    ::Config.from_yaml(config)
  end
end
