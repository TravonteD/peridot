require "./spec_helper"
require "../src/mpd"
require "../src/ui"

class DummyMpdClient
  include MpdClient

  getter state : String | Nil
  getter elapsed_time : Int32
  getter total_time : Int32
  getter bit_rate : Int32
  getter volume : Int32
  getter queue_length : UInt32
  getter current_song : Peridot::MPD::Library::Song | Nil
  getter queue_songs : Array(Peridot::MPD::Library::Song)

  def initialize(@repeat : Bool = false,
                  @random : Bool = false,
                  @single : Bool = false,
                  @consume : Bool = false,
                  @elapsed_time : Int32 = 0,
                  @total_time : Int32 = 0,
                  @bit_rate : Int32 = 0,
                  @volume : Int32 = 0,
                  @queue_length : UInt32 = UInt32.new(0),
                  @current_song : Peridot::MPD::Library::Song | Nil = Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist"),
                  @queue_songs : Array(Peridot::MPD::Library::Song) = [Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist")],
                  @state : String | Nil = nil)
  end

  def play : Void
    @played = {true, nil}
  end

  def play(id : UInt32) : Void
    @played = {true, id}
  end

  def pause : Void; end
  def toggle_pause : Void; end
  def stop : Void; end
  def next : Void; end
  def previous : Void; end
  def repeat : Void; end
  def random : Void; end
  def single : Void; end
  def consume : Void; end
  def increase_volume : Void; end
  def decrease_volume : Void; end

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

  def queue_add(uri : String) : Void
    @queue_length += 1
    @added = {true, uri}
  end

  def artists : Array(Peridot::MPD::Library::Artist)
    artist = Peridot::MPD::Library::Artist.new("test_artist")
    songs = [
      Peridot::MPD::Library::Song.new("test1", "", "", ""),
      Peridot::MPD::Library::Song.new("test2", "", "", "")
      ]
    artist.songs = songs
    [artist]
  end

  def albums : Array(Peridot::MPD::Library::Album)
    artist = Peridot::MPD::Library::Artist.new("test_artist")
    songs = [
      Peridot::MPD::Library::Song.new("test1", "", "", ""),
      Peridot::MPD::Library::Song.new("test2", "", "", "")
      ]
    album = Peridot::MPD::Library::Album.new("test_album", artist)
    album.songs = songs
    [album]
  end

  def songs : Array(Peridot::MPD::Library::Song)
    [Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist")]
  end
end

class DummyUIClient
  include UIClient

  getter width : Int32
  getter height : Int32

  def initialize(@width : Int32 = 0, @height : Int32 = 0); end

  def set_primary_colors(fg : Int32, bg : Int32)
    @primary_colors = {fg, bg}
  end

  def set_output_mode(mode : Int32)
    @output_mode = mode
  end

  def shutdown
    @shutdown = true
  end

  def poll
    @poll = true
  end

  def render
    @render = true
  end

  def empty
    @empty = true
  end

  def clear
    @clear = true
  end

  def <<(arg : Termbox::Element)
    @put = arg
  end
end

describe Peridot::UI do
  it "initializes all of the windows" do
    ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
    expected = [:library, :queue, :status, :playlist, :album, :artist, :song].sort

    ui.@windows.keys.sort.should eq expected
  end

  it "sets the primary window to :queue" do
    ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)

    ui.@primary_window.should eq :queue
  end

  describe "#move_down" do
    it "increments the current windows selected line" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
      ui.select_window(:library)
      line = ui.@windows[:library].@selected_line

      ui.move_down

      ui.@windows[:library].@selected_line.should eq line + 1
    end
  end

  describe "#move_up" do
    it "decrements the current windows selected line" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
      ui.select_window(:library)

      ui.move_down

      ui.@windows[:library].@selected_line.should eq 1

      ui.move_up

      ui.@windows[:library].@selected_line.should eq 0
    end
  end

  describe "#select_window" do
    it "makes the given window the current one" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)

      ui.select_window(:library)

      ui.@current_window.should eq :library
    end
  end
end

describe Peridot::UI::StatusWindow do
  it "properly formats the title" do
    client = DummyMpdClient.new(state: "Stopped")
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    window = Peridot::UI::StatusWindow.new(client, dimensions)
    expected = "Stopped (Random: Off | Repeat: Off | Consume: Off  | Single: Off | Volume: 0%)"

    window.@title.should eq expected
  end

  it "shows the now playing information" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_title", "test_album, test_artist"]
    window = Peridot::UI::StatusWindow.new(client, dimensions)

    window.@lines.should eq expected
  end
end

describe Peridot::UI::QueueWindow do
  it "displays the length of the queue in the title" do
    client = DummyMpdClient.new(queue_length: 5)
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = "Queue (5 Songs)"
    window = Peridot::UI::QueueWindow.new(client, dimensions)

    window.@title.should eq expected
  end

  it "displays the songs in the queue" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_artist - test_title test_album"]
    window = Peridot::UI::QueueWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::QueueWindow.new(client, dimensions)
      window.selected_line = 1

      window.action

      expected = {true, 1}
      client.@played.should eq expected
    end
  end
end

describe Peridot::UI::SongWindow do
  it "displays the songs in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_title test_album, test_artist"]
    window = Peridot::UI::SongWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
    it "adds the selected song to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.action

      expected = {true, "test_uri"}
      client.@added.should eq expected
      client.@queue_length.should eq 1
    end

    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.action

      expected = {true, 0}
      client.@played.should eq expected
    end
  end
end

describe Peridot::UI::AlbumWindow do
  it "displays the albums in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_album"]
    window = Peridot::UI::AlbumWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
      it "adds the selected albums songs to the queue" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::AlbumWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        client.@queue_length.should eq 2
      end

      it "plays the first song in the album" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::AlbumWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        expected = {true, 0}
        client.@played.should eq expected
      end
  end
end

describe Peridot::UI::ArtistWindow do
  it "displays the artists in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_artist"]
    window = Peridot::UI::ArtistWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
      it "adds the selected artists songs to the queue" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::ArtistWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        client.@queue_length.should eq 2
      end

      it "plays the first song that was added" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::ArtistWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        expected = {true, 0}
        client.@played.should eq expected
      end
  end
end
