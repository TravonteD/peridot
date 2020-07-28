require "./ui"
require "./mpd"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))

def format_line_margin(start_string : String, end_string : String, width : Int32) : String
    margin = " " * (width - (start_string.size + end_string.size) - 2)
    start_string + margin + end_string
end

def calculate_window_dimensions(max_width : Int32, max_height : Int32)
  status_width = playlist_width = max_width - 2
  status_height = 4
  playlist_height = max_height - 2 - status_height
  {
    playlist: {
      x: 1,
      y: 1,
      w: playlist_width,
      h: playlist_height
    },
    status: {
      x: 1,
      y: max_height - status_height - 1,
      w: status_width,
      h: status_height
    }
  }
end

begin
  mpd = Peridot::MPD.new("localhost", 6600)
  main_window = Peridot::UI.init

  # Dimensions
  dimensions = calculate_window_dimensions(main_window.width, main_window.height)

  # Playlist Window
  songs = mpd.queue.songs.map { |x| format_line_margin("#{x.artist} - #{x.title}", "#{x.album}", dimensions[:playlist][:w]) }
  selected_song = 0
  playlist_window = Peridot::UI::Window.new("Queue (#{songs.size} Songs)", dimensions[:playlist])
  playlist_window.write_lines(songs, selected_song)
  main_window << playlist_window.container

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
        mpd.play(mpd.queue.songs[selected_song].id)
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
          selected_song += 1 unless selected_song == (songs.size - 1)
        when 'k'
          selected_song -= 1 unless selected_song == 0
        end
      end
    end

    # Rerender status window
    status_window.add_title(mpd.formatted_status)
    status_window.write_lines(mpd.now_playing_stats)

    # Rerender playlist window
    playlist_window.write_lines(songs, selected_song)

    main_window.render
  end
ensure
  main_window.shutdown if main_window
end
