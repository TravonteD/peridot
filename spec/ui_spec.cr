require "./spec_helper"
require "../src/mpd"
require "../src/ui"

struct DummyClient
  include MpdClient

  getter state : String | Nil

  def initialize(@repeat : Bool = false,
                  @random : Bool = false,
                  @single : Bool = false,
                  @consume : Bool = false,
                  @elapsed_time : Int32 = 0,
                  @total_time : Int32 = 0,
                  @bit_rate : Int32 = 0,
                  @volume : Int32 = 0,
                  @state : String | Nil = nil)
  end
  
  def play : Void
  end

  def play(id : UInt32) : Void
  end

  def pause : Void
  end

  def toggle_pause : Void
  end

  def stop : Void
  end

  def next : Void
  end

  def previous : Void
  end

  def repeat : Void
  end

  def random : Void
  end

  def single : Void
  end

  def consume : Void
  end

  # def state : String | Nil
  #   @state
  # end

  def volume : Int32
    @volume
  end
  def repeat? : Bool
    @repeat
  end
  def random? : Bool
    @random
  end
  def single? : Bool
    @single
  end
  def consume? : Bool
    @consume
  end
  def elapsed_time : Int32
    @elapsed_time
  end
  def total_time : Int32
    @total_time
  end
  def bit_rate : Int32
    @bit_rate
  end
  def current_song : Peridot::MPD::Library::Song
    Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist")
  end
  def queue_songs : Array(Peridot::MPD::Library::Song)
  end
  def queue_length : UInt32
  end
  def queue_add(uri : String) : Void
  end
  def artists : Array(Peridot::MPD::Library::Artist)
  end
  def albums : Array(Peridot::MPD::Library::Album)
  end
  def songs : Array(Peridot::MPD::Library::Song)
  end
end

describe Peridot::UI::StatusWindow do
  it "properly formats the title" do
    client = DummyClient.new(state: "Stopped")
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    status_window = Peridot::UI::StatusWindow.new(client, dimensions)
    expected = "Stopped (Random: Off | Repeat: Off | Consume: Off  | Single: Off | Volume: 0%)"

    status_window.@title.should eq expected
  end

  it "shows the now playing information" do
    client = DummyClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_title", "test_album, test_artist"]
    status_window = Peridot::UI::StatusWindow.new(client, dimensions)

    status_window.@lines.should eq expected
  end
end
