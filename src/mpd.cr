require "libmpdclient"

module MpdClient
  abstract def now_playing_stats : Array(String)
  abstract def formatted_status : String
  abstract def play : Void
  abstract def play(id : UInt32) : Void
  abstract def pause : Void
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
  abstract def repeat? : Bool
  abstract def random? : Bool
  abstract def single? : Bool
  abstract def consume? : Bool
  abstract def elapsed_time : Int32
  abstract def total_time : Int32
  abstract def bit_rate : Int32
  abstract def current_song : Peridot::MPD::Song | Nil
  abstract def queue_songs : Array(Peridot::MPD::Song)
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
    @connection = LibMpdClient.mpd_connection_new(host, port, 1000) # Timeout is 1 second for now
    @queue = Queue.new(@connection)
    @library = Library.new(@connection)
    @library.init
  end

  def now_playing_stats : Array(String)
    if current_song
      [current_song.not_nil!.title, "#{current_song.not_nil!.album}, #{current_song.not_nil!.artist}"]
    else
      ["", "", ""]
    end
  end

  def formatted_status : String
    sprintf("%s (Random: %s | Repeat: %s | Consume: %s  | Single: %s | Volume: %s%%)",
      self.state.capitalize,
      self.random? ? "On" : "Off",
      self.repeat? ? "On" : "Off",
      self.consume? ? "On" : "Off",
      self.single? ? "On" : "Off",
      self.volume,
    )
  end

  def play : Void
    LibMpdClient.mpd_run_play(@connection)
  end

  def play(id : UInt32) : Void
    LibMpdClient.mpd_run_play_id(@connection, id)
  end

  def pause : Void
    LibMpdClient.mpd_run_pause(@connection)
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
    LibMpdClient.mpd_run_repeat(self.status)
  end

  def random : Void
    LibMpdClient.mpd_run_random(self.status)
  end

  def single : Void
    LibMpdClient.mpd_run_single(self.status)
  end

  def consume : Void
    LibMpdClient.mpd_run_consume(self.status)
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

  def elapsed_time : Int32
    LibMpdClient.mpd_status_get_elapsed_time(self.status)
  end

  def total_time : Int32
    LibMpdClient.mpd_status_get_total_time(self.status)
  end

  # rate is in kilobits
  def bit_rate : Int32
    LibMpdClient.mpd_status_get_bit_rate(self.status)
  end

  def current_song : Song | Nil
    song_id = LibMpdClient.mpd_status_get_song_id(self.status)
    @queue.songs.find { |x| x.id == song_id }
  end

  def queue_songs : Array(Peridot::MPD::Song)
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

  private def status : LibMpdClient::MpdStatus*
    LibMpdClient.mpd_run_status(@connection)
  end
end

struct Peridot::MPD::Queue
  def initialize(@connection : LibMpdClient::MpdConnection*); end

  def length : UInt32
    status = LibMpdClient.mpd_run_status(@connection)
    LibMpdClient.mpd_status_get_queue_length(status)
  end

  def songs : Array(Peridot::MPD::Song)
    songs = [] of Peridot::MPD::Song
    return songs if length.zero?

    (0..self.length - 1).each do |i|
      songs << Peridot::MPD::Song.new(@connection, LibMpdClient.mpd_run_get_queue_song_pos(@connection, i))
    end
    songs
  end

  def add(uri : String)
    LibMpdClient.mpd_run_add(@connection, uri)
  end
end

struct Peridot::MPD::Song
  def initialize(@connection : LibMpdClient::MpdConnection*, @song : LibMpdClient::MpdSong*); end

  def uri : String
    String.new(LibMpdClient.mpd_song_get_uri(@song))
  end

  def id : UInt32
    LibMpdClient.mpd_song_get_id(@song)
  end

  def artist
    tag(:artist)
  end

  def album
    tag(:album)
  end

  def album_artist
    tag(:album_artist)
  end

  def title
    tag(:title)
  end

  def track
    tag(:track)
  end

  def name
    tag(:name)
  end

  def genre
    tag(:genre)
  end

  def date
    tag(:date)
  end

  private def tag(tag_name : Symbol) : String
    tags = {
      artist:       LibMpdClient::MpdTagType::MPD_TAG_ARTIST,
      album:        LibMpdClient::MpdTagType::MPD_TAG_ALBUM,
      album_artist: LibMpdClient::MpdTagType::MPD_TAG_ALBUM_ARTIST,
      title:        LibMpdClient::MpdTagType::MPD_TAG_TITLE,
      track:        LibMpdClient::MpdTagType::MPD_TAG_TRACK,
      name:         LibMpdClient::MpdTagType::MPD_TAG_NAME,
      genre:        LibMpdClient::MpdTagType::MPD_TAG_GENRE,
      date:         LibMpdClient::MpdTagType::MPD_TAG_DATE,
    }
    String.new(LibMpdClient.mpd_song_get_tag(@song, tags[tag_name], 0))
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
