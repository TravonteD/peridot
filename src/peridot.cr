require "./ui"
require "./mpd"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))

def format_line_margin(start_string : String, end_string : String, width : Int32) : String
    margin = " " * (width - (start_string.size + end_string.size) - 2)
    start_string + margin + end_string
end

def calculate_window_dimensions(max_width : Int32, max_height : Int32)
  status_width = queue_width = max_width - 2
  library_width = playlist_width = 15
  library_height = 5
  queue_width -= library_width
  status_height = 4
  queue_height = max_height - 2 - status_height
  playlist_height = max_height - 2 - status_height - library_height
  {
    playlist: {
      x: 1,
      y: library_height + 1,
      w: playlist_width,
      h: playlist_height
    },
    library: {
      x: 1,
      y: 1,
      w: library_width,
      h: library_height
    },
    queue: {
      x: library_width + 1,
      y: 1,
      w: queue_width,
      h: queue_height
    },
    status: {
      x: 1,
      y: max_height - status_height - 1,
      w: status_width,
      h: status_height
    }
  }
end

def main
  begin
    mpd = Peridot::MPD.new("localhost", 6600)
    main_window = Peridot::UI.init

    # Dimensions
    dimensions = calculate_window_dimensions(main_window.width, main_window.height)

    # Library Window
    categories = ["Queue", "Songs", "Artists", "Albums"]
    library_window = Peridot::UI::Window.new("Library", dimensions[:library])
    library_selected = 0
    library_window.write_lines(categories, library_selected)
    main_window << library_window.container

    # Playlist Window
    playlist_window = Peridot::UI::Window.new("Playlists", dimensions[:playlist])
    main_window << playlist_window.container

    # Queue Window
    songs = mpd.queue.songs.map { |x| format_line_margin("#{x.artist} - #{x.title}", "#{x.album}", dimensions[:queue][:w]) }
    queue_selected = 0
    queue_window = Peridot::UI::Window.new("Queue (#{songs.size} Songs)", dimensions[:queue])
    queue_window.write_lines(songs, queue_selected)
    main_window << queue_window.container

    # Status Window
    status_window = Peridot::UI::Window.new(mpd.formatted_status, dimensions[:status])
    status_window.write_lines(mpd.now_playing_stats)
    main_window << status_window.container

    main_window.render

    # Main Event loop
    loop do
      ev = main_window.poll

      case ev.type
      when Termbox::EVENT_KEY
        case ev.key
        when Termbox::KEY_CTRL_C, Termbox::KEY_CTRL_D
          break
        when Termbox::KEY_ENTER
          mpd.play(mpd.queue.songs[queue_selected].id)
        else
          case ev.ch.chr
          when 'q'
            break
          when '>'
            mpd.next
          when '<'
            mpd.previous
          when 's'
            mpd.stop
          when 'p'
            mpd.toggle_pause
          when 'j'
            queue_selected += 1 unless queue_selected == (songs.size - 1)
            # Rerender queue window
            queue_window.write_lines(songs, queue_selected)
          when 'k'
            queue_selected -= 1 unless queue_selected == 0
            # Rerender queue window
            queue_window.write_lines(songs, queue_selected)
          end
        end
      end

      # Rerender status window
      status_window.add_title(mpd.formatted_status)
      status_window.write_lines(mpd.now_playing_stats)

      main_window.render
    end
  ensure
    main_window.shutdown if main_window
  end
end

def fetch_library
  connection = LibMpdClient.mpd_connection_new("localhost", 6600, 1000) # Timeout is 1 second for now
  if LibMpdClient.mpd_send_list_all_meta(connection, "")
    while (entity = LibMpdClient.mpd_recv_entity(connection))
      entity_type = LibMpdClient.mpd_entity_get_type(entity)
      case entity_type
      when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_DIRECTORY
        directory = LibMpdClient.mpd_entity_get_directory(entity)
        path = String.new(LibMpdClient.mpd_directory_get_path(directory))
      when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_SONG
        song = LibMpdClient.mpd_entity_get_song(entity)
        mpd_song = Peridot::MPD::Song.new(connection, song)
      when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_PLAYLIST
        playlist = LibMpdClient.mpd_entity_get_playlist(entity)
        path = LibMpdClient.mpd_playlist_get_path(playlist)
      when LibMpdClient::MpdEntityType::MPD_ENTITY_TYPE_UNKNOWN
        Log.warn{"unknown entity received"}
      else
        Log.warn{"invalid entity_type returned"}
      end
    end
  end
end

main
