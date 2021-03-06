require "yaml"

DEFAULT_CONFIG= <<-END
---
keys:
  focus_primary_window: "1"
  focus_library_window: "2"
  focus_playlist_window: "3"
  move_down: "j"
  move_up: "k"
  previous: "<"
  next: ">"
  toggle_pause: "p"
  stop: "s"
  toggle_repeat: "r"
  toggle_random: "z"
  toggle_single: "y"
  toggle_consume: "R"
  volume_up: "+"
  volume_down: "-"
  seek_forward: "f"
  seek_backward: "b"
  queue_remove: "D"
  queue_clear: "c"
  filter: "l"
  unfilter: "h"

colors:
  foreground: 8
  background: 0
  foreground_select: 3
  background_select: 0

server:
  host: "localhost"
  port: 6600
END

struct Server
  include YAML::Serializable

  property host : String
  property port : Int32
end

struct Keybinding::Format
  @@valid_commands = [
    "focus_primary_window",
    "focus_library_window",
    "focus_playlist_window",
    "move_up",
    "move_down",
    "play",
    "toggle_pause",
    "stop",
    "next",
    "previous",
    "toggle_repeat",
    "toggle_single",
    "toggle_consume",
    "toggle_random",
    "volume_up",
    "volume_down",
    "seek_forward",
    "seek_backward",
    "queue_remove",
    "queue_clear",
    "filter",
    "unfilter",
  ]

  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Hash(String, String)
    result = {} of String => String
    node.as(YAML::Nodes::Mapping).each do |k, v|
      next unless @@valid_commands.includes?(k.as(YAML::Nodes::Scalar).value)
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
