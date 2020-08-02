require "spec"
require "../src/ui"
require "../src/mpd"
require "../src/config"

CONFIG = Peridot::Config.parse(File.read("test_config.yml"))

class DummyMpdClient
  include MpdClient

  getter state : String | Nil
  getter elapsed_time : UInt32
  getter total_time : UInt32
  getter bit_rate : Int32
  getter volume : Int32
  getter queue_length : UInt32
  getter current_song : Peridot::MPD::Library::Song | Nil
  getter queue_songs : Array(Peridot::MPD::Library::Song)
  getter songs : Array(Peridot::MPD::Library::Song)

  def initialize(@repeat : Bool = false,
                  @random : Bool = false,
                  @single : Bool = false,
                  @consume : Bool = false,
                  @elapsed_time : UInt32 = 0,
                  @total_time : UInt32 = 0,
                  @bit_rate : Int32 = 0,
                  @volume : Int32 = 0,
                  @queue_length : UInt32 = UInt32.new(0),
                  @current_song : Peridot::MPD::Library::Song | Nil = Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist"),
                  @queue_songs : Array(Peridot::MPD::Library::Song) = [Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist")],
                  @songs : Array(Peridot::MPD::Library::Song) = [Peridot::MPD::Library::Song.new("test_uri", "test_title", "test_album", "test_artist")],
                  @albums : Array(Peridot::MPD::Library::Album) = [] of Peridot::MPD::Library::Album,
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
  def seek_forward : Void; end
  def seek_backward : Void; end

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

  def queue_delete(pos : UInt32) : Void
    @queue_length -= 1
    @deleted = {true, pos}
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
    return @albums unless @albums.empty?
    artist = Peridot::MPD::Library::Artist.new("test_artist")
    songs = [
      Peridot::MPD::Library::Song.new("test1", "", "", ""),
      Peridot::MPD::Library::Song.new("test2", "", "", "")
      ]
    album = Peridot::MPD::Library::Album.new("test_album", artist)
    album.songs = songs
    [album]
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
