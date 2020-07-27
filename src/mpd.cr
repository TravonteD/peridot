require "libmpdclient"

struct Peridot::MPD
  getter :connection

  def initialize(host : String, port : Int32)
    @connection = LibMpdClient.mpd_connection_new(host, port, 1000) # Timeout is 1 second for now
  end

  def state
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

  def volume 
    LibMpdClient.mpd_status_get_volume(self.status)
  end

  def repeat 
    LibMpdClient.mpd_status_get_repeat(self.status)
  end

  def random 
    LibMpdClient.mpd_status_get_random(self.status)
  end

  def single 
    LibMpdClient.mpd_status_get_single(self.status)
  end

  def consume 
    LibMpdClient.mpd_status_get_consume(self.status)
  end

  def elapsed_time 
    LibMpdClient.mpd_status_get_elapsed_time(self.status)
  end

  def total_time 
    LibMpdClient.mpd_status_get_total_time(self.status)
  end

  def bit_rate 
    LibMpdClient.mpd_status_get_bit_rate(self.status)
  end

  private def status
    LibMpdClient.mpd_run_status(@connection)
  end
end

struct Peridot::MPD::Queue
  def initialize(connection : LibMpdClient::MpdConnection*)
    @connection = connection
  end
end

struct Peridot::MPD::Song
  def initialize(connection : LibMpdClient::MpdConnection*, song : LibMpdClient::MpdSong*)
    @connection = connection
    @song = song
  end
end
