require "libmpdclient"

struct Peridot::MPD
  getter :queue

  def initialize(host : String, port : Int32)
    @connection = LibMpdClient.mpd_connection_new(host, port, 1000) # Timeout is 1 second for now
    @queue = Queue.new(@connection)
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

  private def status : LibMpdClient::MpdStatus*
    LibMpdClient.mpd_run_status(@connection)
  end
end

struct Peridot::MPD::Queue
  def initialize(connection : LibMpdClient::MpdConnection*)
    @connection = connection
  end

  def length : UInt32
    status = LibMpdClient.mpd_run_status(@connection)
    LibMpdClient.mpd_status_get_queue_length(status)
  end

  def songs : Array(Peridot::MPD::Song)
    songs = [] of Peridot::MPD::Song
    (0..self.length - 1).each do |i|
      songs << Peridot::MPD::Song.new(@connection, LibMpdClient.mpd_run_get_queue_song_pos(@connection, i))
    end
    songs
  end
end

struct Peridot::MPD::Song
  def initialize(connection : LibMpdClient::MpdConnection*, song : LibMpdClient::MpdSong*)
    @connection = connection
    @song = song
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
      artist: LibMpdClient::MpdTagType::MPD_TAG_ARTIST,
      album: LibMpdClient::MpdTagType::MPD_TAG_ALBUM,
      album_artist: LibMpdClient::MpdTagType::MPD_TAG_ALBUM_ARTIST,
      title: LibMpdClient::MpdTagType::MPD_TAG_TITLE,
      track: LibMpdClient::MpdTagType::MPD_TAG_TRACK,
      name: LibMpdClient::MpdTagType::MPD_TAG_NAME,
      genre: LibMpdClient::MpdTagType::MPD_TAG_GENRE,
      date: LibMpdClient::MpdTagType::MPD_TAG_DATE,
    }
    String.new(LibMpdClient.mpd_song_get_tag(@song, tags[tag_name], 0))
  end
end
