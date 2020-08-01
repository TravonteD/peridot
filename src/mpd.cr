require "libmpdclient"

module MpdClient
  abstract def play : Void
  abstract def play(id : UInt32) : Void
  abstract def toggle_pause : Void
  abstract def stop : Void
  abstract def next : Void
  abstract def previous : Void
  abstract def repeat : Void
  abstract def random : Void
  abstract def single : Void
  abstract def consume : Void
  abstract def state : String | Nil
  abstract def volume : Int32
  abstract def increase_volume : Void
  abstract def decrease_volume : Void
  abstract def repeat? : Bool
  abstract def random? : Bool
  abstract def single? : Bool
  abstract def consume? : Bool
  abstract def elapsed_time : UInt32
  abstract def total_time : UInt32
  abstract def bit_rate : Int32
  abstract def current_song : Peridot::MPD::Library::Song | Nil
  abstract def queue_songs : Array(Peridot::MPD::Library::Song)
  abstract def queue_length : UInt32
  abstract def queue_add(uri : String) : Void
  abstract def artists : Array(Peridot::MPD::Library::Artist)
  abstract def albums : Array(Peridot::MPD::Library::Album)
  abstract def songs : Array(Peridot::MPD::Library::Song)
end

struct Peridot::MPD
  include MpdClient

  getter :queue
  getter :library

  def initialize(host : String, port : Int32)
    @connection = LibMpdClient.mpd_connection_new(host, port, 0)
    @library = Library.new(@connection)
    @queue = Queue.new(@connection)
    @library.init
  end

  def play : Void
    LibMpdClient.mpd_run_play(@connection)
  end

  def play(pos : UInt32) : Void
    LibMpdClient.mpd_run_play_pos(@connection, pos)
  end

  def toggle_pause : Void
    LibMpdClient.mpd_run_toggle_pause(@connection)
  end

  def stop : Void
    LibMpdClient.mpd_run_stop(@connection)
  end

  def next : Void
    LibMpdClient.mpd_run_next(@connection)
  end

  def previous : Void
    LibMpdClient.mpd_run_previous(@connection)
  end

  def repeat : Void
    LibMpdClient.mpd_run_repeat(@connection, !self.repeat?)
  end

  def random : Void
    LibMpdClient.mpd_run_random(@connection, !self.random?)
  end

  def single : Void
    LibMpdClient.mpd_run_single(@connection, !self.single?)
  end

  def consume : Void
    LibMpdClient.mpd_run_consume(@connection, !self.consume?)
  end

  def state : String | Nil
    case LibMpdClient.mpd_status_get_state(self.status)
    when LibMpdClient::MpdState::MPD_STATE_PLAY
      "playing"
    when LibMpdClient::MpdState::MPD_STATE_PAUSE
      "paused"
    when LibMpdClient::MpdState::MPD_STATE_STOP
      "stopped"
    when LibMpdClient::MpdState::MPD_STATE_UNKNOWN
      "unknown"
    else
      raise "Invalid state received from server"
    end
  end

  def volume : Int32
    LibMpdClient.mpd_status_get_volume(self.status)
  end

  def repeat? : Bool
    LibMpdClient.mpd_status_get_repeat(self.status)
  end

  def random? : Bool
    LibMpdClient.mpd_status_get_random(self.status)
  end

  def single? : Bool
    LibMpdClient.mpd_status_get_single(self.status)
  end

  def consume? : Bool
    LibMpdClient.mpd_status_get_consume(self.status)
  end

  def elapsed_time : UInt32
    LibMpdClient.mpd_status_get_elapsed_time(self.status)
  end

  def total_time : UInt32
    LibMpdClient.mpd_status_get_total_time(self.status)
  end

  # rate is in kilobits
  def bit_rate : Int32
    LibMpdClient.mpd_status_get_bit_rate(self.status)
  end

  def current_song : Peridot::MPD::Library::Song
    song = LibMpdClient.mpd_run_current_song(@connection)
    uri = String.new(LibMpdClient.mpd_song_get_uri(song))
    @queue.songs.find { |x| x.uri == uri }.not_nil!
  end

  def queue_songs : Array(Peridot::MPD::Library::Song)
    @queue.songs
  end

  def queue_length : UInt32
    @queue.length
  end

  def queue_add(uri : String) : Void
    @queue.add(uri)
  end

  def artists : Array(Peridot::MPD::Library::Artist)
    @library.artists
  end

  def albums : Array(Peridot::MPD::Library::Album)
    @library.albums
  end

  def songs : Array(Peridot::MPD::Library::Song)
    @library.songs
  end

  def increase_volume : Void
    current_volume = self.volume
    return if current_volume == 100
    LibMpdClient.mpd_run_set_volume(@connection, current_volume + 2)
  end

  def decrease_volume : Void
    current_volume = self.volume
    return if current_volume <= 0
    LibMpdClient.mpd_run_set_volume(@connection, current_volume - 2)
  end

  private def status : LibMpdClient::MpdStatus*
    status = LibMpdClient.mpd_run_status(@connection)
    if status.null?
      @connection = LibMpdClient.mpd_connection_new(CONFIG.server.host, CONFIG.server.port, 0)
      status = LibMpdClient.mpd_run_status(@connection)
    end
    status
  end
end

struct Peridot::MPD::Queue
  def initialize(@connection : LibMpdClient::MpdConnection*); end

  def length : UInt32
    status = LibMpdClient.mpd_run_status(@connection)
    if status.null?
      @connection = LibMpdClient.mpd_connection_new(CONFIG.server.host, CONFIG.server.port, 0)
      status = LibMpdClient.mpd_run_status(@connection)
    end
    LibMpdClient.mpd_status_get_queue_length(status)
  end

  def songs : Array(Peridot::MPD::Library::Song)
    songs = [] of Peridot::MPD::Library::Song
    return songs if length.zero?

    (0..self.length - 1).each do |i|
      song = LibMpdClient.mpd_run_get_queue_song_pos(@connection, i)
      uri = String.new(LibMpdClient.mpd_song_get_uri(song))
      title = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_TITLE, 0))
      album = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_ALBUM, 0))
      artist = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_ARTIST, 0))
      songs << Peridot::MPD::Library::Song.new(uri, title, album, artist)
    end
    songs
  end

  def add(uri : String)
    LibMpdClient.mpd_run_add(@connection, uri)
  end
end

struct Peridot::MPD::Library
  getter :artists
  getter :albums
  getter :songs
  getter :playlists

  def initialize(@connection : LibMpdClient::MpdConnection*)
    @artists = [] of Artist
    @albums = [] of Album
    @songs = [] of Song
    @playlists = [] of String
  end

  def init : Void
    if LibMpdClient.mpd_send_list_all_meta(@connection, "")
      while (entity = LibMpdClient.mpd_recv_entity(@connection))
        case LibMpdClient.mpd_entity_get_type(entity)
        when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_DIRECTORY
          next
        when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_UNKNOWN
          Log.warn { "unknown entity received" }
          next
        when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_SONG
          song = LibMpdClient.mpd_entity_get_song(entity)
          import_metadata(song)
        when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_PLAYLIST
          playlist = LibMpdClient.mpd_entity_get_playlist(entity)
          path = String.new(LibMpdClient.mpd_playlist_get_path(playlist))
          @playlists << path
        else
          Log.warn { "invalid entity_type returned" }
        end
      end
    end
  end

  private def import_metadata(mpd_song : LibMpdClient::MpdSong*)
    song = get_song(mpd_song)
    artist_name = song.artist
    album_name = song.album
    artist = get_artist(artist_name)
    album = get_album(album_name, artist)

    artist.songs << song
    album.songs << song
    @songs << song
  end

  private def get_song(song : LibMpdClient::MpdSong*) : Peridot::MPD::Library::Song
    uri = String.new(LibMpdClient.mpd_song_get_uri(song))
    title = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_TITLE, 0))
    album = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_ALBUM, 0))
    artist = String.new(LibMpdClient.mpd_song_get_tag(song, LibMpdClient::MpdTagType::MPD_TAG_ARTIST, 0))
    Peridot::MPD::Library::Song.new(uri, title, album, artist)
  end

  private def get_artist(name : String) : Peridot::MPD::Library::Artist
    if @artists.find { |x| x.name == name }
      @artists.find { |x| x.name == name }.not_nil!
    else
      artist = Peridot::MPD::Library::Artist.new(name)
      @artists << artist
      artist
    end
  end

  private def get_album(name : String, artist : Peridot::MPD::Library::Artist) : Peridot::MPD::Library::Album
    if @albums.find { |x| x.name == name }
      @albums.find { |x| x.name == name }.not_nil!
    else
      album = Peridot::MPD::Library::Album.new(name, artist)
      @albums << album
      album
    end
  end
end

struct Peridot::MPD::Library::Album
  getter name : String
  property artist : Artist
  property songs : Array(Song)

  def initialize(@name : String, @artist : Artist)
    @songs = [] of Song
  end
end

struct Peridot::MPD::Library::Artist
  getter name : String
  property albums : Array(Album)
  property songs : Array(Song)

  def initialize(@name : String)
    @albums = [] of Album
    @songs = [] of Song
  end
end

struct Peridot::MPD::Library::Song
  getter uri : String
  getter title : String
  getter album : String
  getter artist : String

  def initialize(@uri : String, @title : String, @album : String, @artist : String); end
end
