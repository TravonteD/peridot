require "./ui"
require "./mpd"
require "log"

Log.setup(:debug, Log::IOBackend.new(File.new("debug.log", "w")))

def main
  begin
    mpd = Peridot::MPD.new("localhost", 6600)
    ui = Peridot::UI.new(mpd)

    # Library Window
    categories = ["Queue", "Songs", "Artists", "Albums"]
    library_selected = 0
    ui.windows[:library].write_lines(categories, library_selected)

    # Queue Window
    queue_selected = 0
    songs = ui.songs
    ui.windows[:queue].write_lines(songs, queue_selected)
    # Start with the queue window active
    ui.windows[:queue].select

    # Status Window
    ui.windows[:status].write_lines(mpd.now_playing_stats)

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
          ui.windows[:queue].deselect
          ui.windows[:playlist].deselect
          ui.windows[:library].select
        when Termbox::KEY_CTRL_Q
          ui.windows[:library].deselect
          ui.windows[:playlist].deselect
          ui.windows[:queue].select
        when Termbox::KEY_CTRL_P
          ui.windows[:library].deselect
          ui.windows[:queue].deselect
          ui.windows[:playlist].select
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
            ui.windows[:queue].write_lines(songs, queue_selected)
          when 'k'
            queue_selected -= 1 unless queue_selected == 0
            # Rerender queue window
            ui.windows[:queue].write_lines(songs, queue_selected)
          end
        end
      end

      # Rerender status window
      ui.windows[:status].add_title(mpd.formatted_status)
      ui.windows[:status].write_lines(mpd.now_playing_stats)

      ui.render
    end
  ensure
    ui.shutdown if ui
  end
end

main
