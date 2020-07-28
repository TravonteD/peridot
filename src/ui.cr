require "termbox"

include Termbox

struct Peridot::UI
  getter windows : Hash(Symbol, Window)
  getter songs : Array(String)
  getter current_window : Symbol | Nil

  def initialize(mpd : Peridot::MPD)
    @mpd = mpd
    @w = Termbox::Window.new
    @songs = [] of String
    @windows = {} of Symbol => Window
    setup_main_window
    create_child_windows
  end

  def render
    @w.render
  end

  def poll
    @w.poll
  end

  def shutdown
    @w.shutdown
  end

  def select_window(name : Symbol)
    @windows.each do |k, v|
      v.deselect
      v.select if k == name
      Log.info { k }
    end
    @current_window = name
    Log.info { "Selected window #{@current_window}"}
  end

  private def setup_main_window
    @w.set_output_mode(OUTPUT_NORMAL)
    @w.set_primary_colors(8, 0)
    @w.clear
    @w << Border.new(@w)
  end

  private def create_child_windows
    dimensions = calculate_window_dimensions
    @songs = @mpd.queue.songs.map { |x| format_line_margin("#{x.artist} - #{x.title}", "#{x.album}", dimensions[:queue][:w]) }
    @windows[:library] = Peridot::UI::Window.new("Library", dimensions[:library])
    @windows[:playlist] = Peridot::UI::Window.new("Playlists", dimensions[:playlist])
    @windows[:queue] = Peridot::UI::Window.new("Queue (#{songs.size} Songs)", dimensions[:queue])
    @windows[:status] = Peridot::UI::Window.new(@mpd.formatted_status, dimensions[:status])
    @windows.values.each { |x| @w << x.container }
  end

  private def calculate_window_dimensions
    max_width = @w.width
    max_height = @w.height
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

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin = " " * (width - (start_string.size + end_string.size) - 2)
      start_string + margin + end_string
  end
end

# Represents a termbox container used as a window within the UI
struct Peridot::UI::Window
  getter container : Termbox::Container

  def initialize(title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @container = Container.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
    @border = Border.new(container)
    @container << @border
    @offset = 0
    add_title(title)
  end

  def write_line(text : String, line : Int32)
    text.chars.each.with_index do |char, column|
      @container << Cell.new(char, Position.new(column + 1, line))
      column += 1
    end
  end

  # Writes the line using the given colors
  def write_line(text : String, line : Int32, fg : Int32, bg : Int32)
    text.chars.each.with_index do |char, column|
      @container << Cell.new(char, Position.new(column + 1, line), fg, bg)
      column += 1
    end
  end

  # Note: This will truncate the lines if they extend beyond the containers boundary
  def write_lines(lines : Array(String))
    clear

    lines.each.with_index do |line, row|
      write_line(line, row + 1)
      break if row + 1 == @container.height - 2
    end
  end

  # Writes lines with the selected line highlighted
  def write_lines(lines : Array(String), selected_index : Int32)
    clear

    max_height = @container.height - 2
    if (selected_index - @offset) == max_height
      @offset += 1
    end
    if (selected_index - @offset) < 0
      @offset -= 1 unless @offset == 0
    end
    selected_index -= @offset

    lines[@offset..].each.with_index do |line, row|
      if row == selected_index
        write_line(line, row + 1, 2, 0)
      else
        write_line(line, row + 1)
      end
      break if row + 1 == max_height
    end
  end

  def add_title(title : String)
    write_line(title, 0)
  end

  def select
    @border.foreground = 2
  end

  def deselect
    @border.foreground = 8
  end

  def clear
    (0..@container.height).each.with_index do |line, row|
        write_line((" " * (@container.width - 2)), row + 1)
        break if row + 1 == @container.height - 2
    end
 end
end
