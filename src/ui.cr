require "termbox"

include Termbox

# Extends a termbox window to allow for element clearing
class Peridot::TWindow < Termbox::Window
  def initialize
    super
  end

  def empty
    @elements = [] of Element
  end
end
class Peridot::TContainer < Termbox::Container
  def initialize(@pivot : Position, @width : Int32, @height : Int32)
    super
  end

  def empty
    @elements = [] of Element
  end
end

class Peridot::UI
  getter windows : Hash(Symbol, Window)
  getter songs : Array(String)
  getter current_window : Symbol | Nil
  property primary_window : Symbol | Nil

  def initialize(@mpd : MpdClient)
    @w = Peridot::TWindow.new
    @border = Border.new(@w)
    @songs = [] of String
    @windows = {} of Symbol => Window
    setup_main_window
    create_child_windows
  end

  def empty
    @w.empty
  end

  def clear
    @w.clear
  end

  def move_down(window_name : Symbol)
    @windows[window_name].selected_line += 1 unless @windows[window_name].selected_line == (@windows[window_name].lines.size - 1)
    @windows[window_name].draw
  end

  def move_up(window_name : Symbol)
    @windows[window_name].selected_line -= 1 unless @windows[window_name].selected_line == 0
    @windows[window_name].draw
  end

  def redraw
    @w.clear
    @w.empty
    @w << @border
    [:library, :status, :playlist].each { |x| @w << @windows[x].container }
    @w << @windows[@primary_window.not_nil!].container
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
    end
    @current_window = name
  end

  def update_status
    @windows[:status].update
  end

  private def setup_main_window
    @w.set_output_mode(OUTPUT_NORMAL)
    @w.set_primary_colors(8, 0)
    @w.clear
    @w << @border
  end

  private def create_child_windows
    dimensions = calculate_window_dimensions
    @windows[:library] = Peridot::UI::Window.new("Library", dimensions[:library], ["Queue", "Songs", "Artists", "Albums"])
    @windows[:playlist] = Peridot::UI::Window.new("Playlists", dimensions[:playlist])
    @windows[:status] = Peridot::UI::StatusWindow.new(@mpd, dimensions[:status])
    @windows.values.each { |x| @w << x.container }

    @windows[:queue] = Peridot::UI::QueueWindow.new(@mpd, dimensions[:queue])
    @windows[:song] = Peridot::UI::SongWindow.new(@mpd, dimensions[:queue])
    @windows[:album] = Peridot::UI::AlbumWindow.new(@mpd, dimensions[:queue])
    @windows[:artist] = Peridot::UI::ArtistWindow.new(@mpd, dimensions[:queue])

    # Start on the queue window
    @primary_window = :queue

    # Move to the first line in interactive windows
    [:queue, :song, :album, :artist, :library, :playlist].each { |x| move_down(x) }
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
end

# Represents a termbox container used as a window within the UI
class Peridot::UI::Window
  getter container : Peridot::TContainer
  setter title : String
  property lines : Array(String)
  property selected_line : Int32

  def initialize(@title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @container = Peridot::TContainer.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
    @border = Border.new(container)
    @container << @border
    @offset = 0
    add_title
    @lines = [] of String
    @selected_line = -1
  end

  def initialize(@title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32), lines : Array(String))
    @container = Peridot::TContainer.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
    @border = Border.new(container)
    @container << @border
    @offset = 0
    add_title
    @lines = lines
    @selected_line = -1
  end

  def draw
    unless @lines.empty?
      @container.empty
      @container << @border
      add_title
      if @selected_line >= 0
        write_lines(@lines, @selected_line)
      else
        write_lines(@lines)
      end
    end
  end

  def write_line(text : String, line : Int32)
    text.chars.each.with_index do |char, column|
      @container << Cell.new(char, Position.new(column + 1, line))
    end
  end

  # Writes the line using the given colors
  def write_line(text : String, line : Int32, fg : Int32, bg : Int32)
    text.chars.each.with_index do |char, column|
      @container << Cell.new(char, Position.new(column + 1, line), fg, bg)
    end
  end

  # Note: This will truncate the lines if they extend beyond the containers boundary
  def write_lines(lines : Array(String))
    lines.each.with_index do |line, row|
      write_line(line, row + 1)
      break if row + 1 == @container.height - 2
    end
  end

  # Writes lines with the selected line highlighted
  def write_lines(lines : Array(String), selected_index : Int32)
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

  def select
    @border.foreground = 2
  end

  def deselect
    @border.foreground = 8
  end

  # Defined Here to be overriden in child classes
  def update
  end

  # Defined Here to be overriden in child classes
  def action
  end

  private def add_title
    write_line(@title, 0)
  end
end

class Peridot::UI::StatusWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    super(@mpd.formatted_status, dimensions, @mpd.now_playing_stats)
  end

  def update
    @title = @mpd.formatted_status
    @lines = @mpd.now_playing_stats
    draw
  end
end

class Peridot::UI::QueueWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    super("Queue (#{@mpd.queue_songs.size} Songs)", @dimensions, formatted_songs)
  end

  def action
    @mpd.play(@mpd.queue_songs[@selected_line].id)
  end

  def update
    @lines = formatted_songs
    draw
  end

  private def formatted_songs
    @mpd.queue_songs.map { |x| format_line_margin("#{x.artist} - #{x.title}", "#{x.album}", @dimensions[:w]) }
  end

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin = " " * (width - (start_string.size + end_string.size) - 2)
      start_string + margin + end_string
  end
end

class Peridot::UI::SongWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @songs = @mpd.songs.sort { |a, b| a.title <=> b.title }.as(Array(Peridot::MPD::Library::Song))
    super("Songs", @dimensions, formatted_songs)
  end

  def action
    @mpd.queue_add(@songs[@selected_line].uri)
    @mpd.play(@mpd.queue_songs[@mpd.queue_length - 1].id)
  end

  private def formatted_songs
    @songs.map { |x| format_line_margin("#{x.title}", "#{x.album},#{x.artist}", @dimensions[:w]) }
  end

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin = " " * (width - (start_string.size + end_string.size) - 2)
      start_string + margin + end_string
  end
end

class Peridot::UI::AlbumWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @albums = @mpd.albums.sort { |a, b| a.name <=> b.name }.as(Array(Peridot::MPD::Library::Album))
    super("Albums", @dimensions, formatted_albums)
  end

  def action
    songs = @albums[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
    # Play the first song
    @mpd.play(@mpd.queue_songs[@mpd.queue_length - (songs.size)].id)
  end

  private def formatted_albums
    @albums.map { |x| format_line_margin("#{x.name}", "", @dimensions[:w]) }
  end

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin = " " * (width - (start_string.size + end_string.size) - 2)
      start_string + margin + end_string
  end
end

class Peridot::UI::ArtistWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @artists = @mpd.artists.sort { |a, b| a.name <=> b.name }.as(Array(Peridot::MPD::Library::Artist))
    super("Artists", @dimensions, formatted_artists)
  end

  def action
    songs = @artists[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
    # Play the first song
    @mpd.play(@mpd.queue_songs[@mpd.queue_length - (songs.size)].id)
  end

  private def formatted_artists
    @artists.map { |x| format_line_margin("#{x.name}", "", @dimensions[:w]) }
  end

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin = " " * (width - (start_string.size + end_string.size) - 2)
      start_string + margin + end_string
  end
end
