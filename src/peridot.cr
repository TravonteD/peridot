require "./ui"
require "./mpd"
require "./config"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))
CONFIG = Peridot::Config.parse(File.read("test_config.yml"))

def main
  mpd = Peridot::MPD.new(CONFIG["server"]["host"].as_s, CONFIG["server"]["port"].as_i)
  main_window = Peridot::TWindow.new
  ui = Peridot::UI.new(mpd, main_window)

  ui.select_window(ui.primary_window.not_nil!)
  ui.update_status
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
        ui.select_window(ui.primary_window.not_nil!)
      when Termbox::KEY_CTRL_P
        ui.select_window(:playlist)
      when Termbox::KEY_ENTER
        case ui.current_window
        when :queue, :song, :album
          ui.windows[ui.current_window].action
          ui.windows[:queue].update
        when :artist
          ui.windows[:artist].action
          ui.windows[:queue].update
        when :library
          selection = ui.windows[:library].lines[ui.windows[:library].selected_line].downcase
          case selection
          when "queue"
            ui.primary_window = :queue
          when "artists"
            ui.primary_window = :artist
          when "albums"
            ui.primary_window = :album
          when "songs"
            ui.primary_window = :song
          end
          ui.select_window(ui.primary_window.not_nil!)
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

    ui.update_status
    ui.redraw
  end
ensure
  ui.shutdown if ui
end

main
