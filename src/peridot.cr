require "./ui"
require "./mpd"
require "log"

begin
  mpd = Peridot::MPD.new("localhost", 6600)
  main_window = Peridot::UI.init

  # Dimensions
  status_width = playlist_width = main_window.width - 2
  status_height = 4
  playlist_height = main_window.height - 2 - status_height

  # Playlist Window
  playlist_window = Peridot::UI::Window.new("Queue", {x: 1, y: 1, w: playlist_width, h: playlist_height})
  songs = mpd.queue.songs.map { |x| "#{x.artist} - #{x.title}   #{x.album}" }
  selected_song = 0
  playlist_window.write_lines(songs, selected_song)
  main_window << playlist_window.container

  # Status Window
  status_title = "#{mpd.state.capitalize} (Random: #{mpd.random? ? "On" : "Off"} | Repeat: #{mpd.repeat? ? "On" : "Off"} | Consume: #{mpd.consume? ? "On" : "Off"} | | Single: #{mpd.single? ? "On" : "Off"} | Volume: #{mpd.volume}%)"
  status_window = Peridot::UI::Window.new(status_title, {x: 1, y: main_window.height - 5, w: status_width, h: status_height})
  if current_song = mpd.current_song
    stats = [current_song.title, "#{current_song.album}, #{current_song.artist}"]
  else
    stats = ["nil", "nil"]
  end
  status_window.write_lines(stats)
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
          selected_song += 1 unless selected_song == (mpd.queue.length - 1)
        when 'k'
          selected_song -= 1 unless selected_song == 0
        end
      end
    end

    # Rerender status window
    status_window.add_title "#{mpd.state.capitalize} (Random: #{mpd.random? ? "On" : "Off"} | Repeat: #{mpd.repeat? ? "On" : "Off"} | Consume: #{mpd.consume? ? "On" : "Off"} | | Single: #{mpd.single? ? "On" : "Off"} | Volume: #{mpd.volume}%)"
    if current_song = mpd.current_song
      stats = [current_song.title, "#{current_song.album}, #{current_song.artist}"]
    else
      stats = ["nil", "nil"]
    end
    status_window.write_lines(stats)

    # Rerender playlist window
    playlist_window.write_lines(songs, selected_song)

    main_window.render
  end
ensure
  main_window.shutdown if main_window
end
