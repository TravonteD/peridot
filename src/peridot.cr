require "./ui"
require "./mpd"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))

def main
  begin
    mpd = Peridot::MPD.new("localhost", 6600)
    ui = Peridot::UI.new(mpd)

    # Library Window
    ui.windows[:library].selected_line = 0
    ui.windows[:library].draw

    # Queue Window
    ui.windows[:queue].selected_line = 0
    ui.windows[:queue].draw
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
          if ui.current_window == :queue
            mpd.play(mpd.queue.songs[ui.windows[:queue].selected_line].id)
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
            ui.windows[:queue].selected_line += 1 unless ui.windows[:queue].selected_line == (ui.songs.size - 1)
            # Rerender queue window
            ui.windows[:queue].draw
          when 'k'
            ui.windows[:queue].selected_line -= 1 unless ui.windows[:queue].selected_line == 0
            # Rerender queue window
            ui.windows[:queue].draw
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
