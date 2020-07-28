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

    ui.render

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
            when "artists"
              ui.windows[:queue].lines = mpd.library.artists
            when "albums"
              ui.windows[:queue].lines = mpd.library.albums.map { |x| x[1] }
            when "songs"
              ui.windows[:queue].lines = mpd.library.songs.map { |x| x.title }
            end
            ui.windows[:queue].draw
          else
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
            ui.move_down(ui.current_window)
          when 'k'
            ui.move_up(ui.current_window)
          end
        end
      end

      # Rerender status window
      ui.windows[:status].add_title(mpd.formatted_status)
      ui.windows[:status].draw

      ui.render
    end
  ensure
    ui.shutdown if ui
  end
end

main
