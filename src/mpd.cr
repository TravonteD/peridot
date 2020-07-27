require "libmpdclient"

struct Peridot::MPD
  getter :connection

  def initialize(host : String, port : Int32)
    @connection = LibMpdClient.mpd_connection_new(host, port, 1000) # Timeout is 1 second for now
  end
end
