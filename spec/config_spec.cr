require "./spec_helper"
require "../src/config.cr"

dummy_config = <<-END
---
keys:
  j: "move_down" 
  k: "move_up"
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

      config.keys["j"].should eq "move_down"
      config.keys["k"].should eq "move_up"
    end

    it "parses colors" do
      config = Peridot::Config.parse(dummy_config)

      config.colors["foreground"].should eq 8
      config.colors["background"].should eq 0
    end

    it "parses server information" do
      config = Peridot::Config.parse(dummy_config)

      config.server["host"].should eq "localhost"
      config.server["port"].should eq 6600
    end
  end
end
