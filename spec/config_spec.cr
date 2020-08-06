require "./spec_helper"
require "../src/config.cr"

dummy_config = <<-END
---
keys:
  move_down: "j" 
  move_up: "k"
colors:
  foreground: 8
  background: 0
server:
  host: "localhost"
  port: 6600
END

dummy_config_with_key_error = <<-END
---
keys:
  move_down: "j" 
  move_up: "k"
  invalid_command: "a"
colors:
  foreground: 8
  background: 0
server:
  host: "localhost"
  port: 6600
END

describe Peridot::Config do
  describe ".parse" do
    it "parses the keybindings" do
      config = Peridot::Config.parse(dummy_config)

      config.keys.dig("j").should eq "move_down"
      config.keys.dig("k").should eq "move_up"
    end

    it "ignores keybindings to invalid_commands" do
      config = Peridot::Config.parse(dummy_config_with_key_error)
      
      config.keys.keys.should_not contain("a")
    end

    it "parses colors" do
      config = Peridot::Config.parse(dummy_config)

      config.colors["foreground"].should eq 8
      config.colors["background"].should eq 0
    end

    it "parses server information" do
      config = Peridot::Config.parse(dummy_config)

      config.server.host.should eq "localhost"
      config.server.port.should eq 6600
    end
  end
end
