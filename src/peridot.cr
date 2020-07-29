require "./ui"
require "./mpd"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))

def main
  begin
    mpd = Peridot::MPD.new("localhost", 6600)
    ui = Peridot::UI.new(mpd)

    # Move to the first line in both windows
    ui.move_down(:library)
    ui.move_down(:queue)
    ui.move_down(:playlist)

    # Start with the queue window active
    ui.select_window(:queue)

    # Status Window
    ui.windows[:status].draw

    ui.redraw

    # Main Event loop
    loop do
      ev = ui.poll

      case ev.type
      when Termbox::EVENT_KEY
        case ev.key
        when Termbox::KEY_CTRL_C, Termbox::KEY_CTRL_D
          break
        when Termbox::KEY_CTRL_L
          ui.select_window(:library)
        when Termbox::KEY_CTRL_Q
          ui.select_window(:queue)
        when Termbox::KEY_CTRL_P
          ui.select_window(:playlist)
        when Termbox::KEY_ENTER
          case ui.current_window
          when :queue
            mpd.play(mpd.queue.songs[ui.windows[:queue].selected_line].id)
          when :library
            selection = ui.windows[:library].lines[ui.windows[:library].selected_line].downcase
            case selection
            when "queue"
              ui.windows[:queue].lines = ui.songs
              ui.windows[:queue].title = "Queue (#{ui.songs.size} Songs)"
            when "artists"
              ui.windows[:queue].lines = mpd.library.artists.map { |x| x.name }.sort
              ui.windows[:queue].title = "Artists"
            when "albums"
              ui.windows[:queue].lines = mpd.library.albums.map { |x| x.name }.sort
              ui.windows[:queue].title = "Albums"
            when "songs"
              ui.windows[:queue].lines = mpd.library.songs.map { |x| x.title }.sort
              ui.windows[:queue].title = "Songs"
            end
            ui.windows[:queue].draw
          end
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
            ui.move_down(ui.current_window.not_nil!)
          when 'k'
            ui.move_up(ui.current_window.not_nil!)
          end
        end
      end

      # Rerender status window
      ui.windows[:status].title = mpd.formatted_status
      ui.windows[:status].draw

      ui.redraw
    end
  ensure
    ui.shutdown if ui
  end
end

main
