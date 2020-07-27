require "libmpdclient"

struct Peridot::MPD
  getter :connection

  def initialize(host : String, port : Int32)
    @connection = LibMpdClient.mpd_connection_new(host, port, 1000) # Timeout is 1 second for now
  end

  def state : String | Nil
    case LibMpdClient.mpd_get_state(self.status)
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

  private def status : LibMpdClient::MpdStatus*
    LibMpdClient.mpd_run_status(@connection)
  end
end

struct Peridot::MPD::Queue
  def initialize(connection : LibMpdClient::MpdConnection*)
    @connection = connection
  end

  def length : Int32
    status = LibMpdClient.mpd_run_status(@connection)
    LibMpdClient.mpd_status_get_queue_length(status)
  end
end

struct Peridot::MPD::Song
  def initialize(connection : LibMpdClient::MpdConnection*, song : LibMpdClient::MpdSong*)
    @connection = connection
    @song = song
  end
end
