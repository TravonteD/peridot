require "./ui/interface"
require "path"

class Peridot::UI
  getter windows : Hash(Symbol, Window)
  getter current_window : Symbol | Nil
  property primary_window : Symbol | Nil

  def initialize(@mpd : MpdClient, @w : UIClient)
    @border = Peridot::TBorder.new(@w)
    @windows = {} of Symbol => Window
    @commands = {} of String => Proc(Nil)
    setup_main_window
    create_child_windows
    create_commands
  end

  def command(name : String)
    @commands[name].call
  end

  def empty
    @w.empty
  end

  def clear
    @w.clear
  end

  def move_down
    @windows[@current_window].selected_line += 1 unless @windows[@current_window].selected_line == (@windows[@current_window].lines.size - 1)
    @windows[@current_window].draw
  end

  def move_up
    @windows[@current_window].selected_line -= 1 unless @windows[@current_window].selected_line == 0
    @windows[@current_window].draw
  end

  def redraw
    @w.clear
    @w.empty
    @w << @border
    [:library, :status, :playlist].each { |x| @w << @windows[x].container }
    @w << @windows[@primary_window.not_nil!].container
    @w.render
  end

  # Known Issue: Playlist windows border breaks at very short heights
  def resize
    self.redraw
    new_dimensions = self.calculate_window_dimensions
    @windows[:library].resize(new_dimensions[:library])
    @windows[:status].resize(new_dimensions[:status])
    @windows[:playlist].resize(new_dimensions[:playlist])
    @windows[:queue].resize(new_dimensions[:queue])
    @windows[:song].resize(new_dimensions[:queue])
    @windows[:album].resize(new_dimensions[:queue])
    @windows[:artist].resize(new_dimensions[:queue])
    @border = Border.new(@w)
    self.select_window(@current_window.not_nil!)
  end

  def poll
    @w.peek(1000)
  end

  def shutdown
    @w.shutdown
  end

  def select_window(name : Symbol) : Void
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
    @w.set_primary_colors(CONFIG.colors["foreground"], CONFIG.colors["background"])
    @w.clear
    @w << @border
  end

  private def create_child_windows
    dimensions = calculate_window_dimensions
    @windows[:library] = Peridot::UI::Window.new("Library", dimensions[:library], ["Queue", "Songs", "Artists", "Albums"])
    @windows[:playlist] = Peridot::UI::PlaylistWindow.new(@mpd, dimensions[:playlist])
    @windows[:status] = Peridot::UI::StatusWindow.new(@mpd, dimensions[:status])
    @windows.values.each { |x| @w << x.container }

    @windows[:queue] = Peridot::UI::QueueWindow.new(@mpd, dimensions[:queue])
    @windows[:song] = Peridot::UI::SongWindow.new(@mpd, dimensions[:queue])
    @windows[:album] = Peridot::UI::AlbumWindow.new(@mpd, dimensions[:queue])
    @windows[:artist] = Peridot::UI::ArtistWindow.new(@mpd, dimensions[:queue])

    # Start on the queue window
    @primary_window = :queue

    # Move to the first line in interactive windows
    [:queue, :song, :album, :artist, :library, :playlist].each do |x|
      @windows[x].selected_line += 1
      @windows[x].draw
    end
  end

  private def calculate_window_dimensions
    max_width = @w.width
    max_height = @w.height
    status_width = queue_width = max_width - 2
    library_width = playlist_width = 15
    library_height = 5
    queue_width -= library_width
    status_height = 5
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

  private def create_commands
    filter_command = Proc(Nil).new do
      next if @current_window != @primary_window
      next_window = case @primary_window.not_nil!
                    when :artist
                      :album
                    when :album
                      :song
                    else
                      @primary_window
                    end
        next if @primary_window == next_window
        @windows[next_window].filter(@windows[@current_window].current_line)
        self.select_window(next_window.not_nil!)
        @primary_window = next_window
        nil
    end
    unfilter_command = Proc(Nil).new do
      next if @current_window != @primary_window || !@windows[@current_window].filtered?
      next_window = case @primary_window.not_nil!
                    when :album
                      :artist
                    when :song
                      :album
                    else
                      @primary_window
                    end
        next if @primary_window == next_window
        @windows[@current_window].unfilter
        self.select_window(next_window.not_nil!)
        @primary_window = next_window
        nil
    end
    @commands = {
      "focus_primary_window" => ->{ self.select_window(@primary_window.not_nil!) },
      "focus_library_window" => ->{ self.select_window(:library) },
      "focus_playlist_window" => ->{ self.select_window(:playlist) },
      "move_up" => ->{ self.move_up },
      "move_down" => ->{ self.move_down },
      "play" => ->{ @mpd.play },
      "toggle_pause" => ->{ (@mpd.state == "stopped") ? @mpd.play : @mpd.toggle_pause },
      "stop" => ->{ @mpd.stop },
      "next" => ->{ @mpd.next },
      "previous" => ->{ @mpd.previous },
      "toggle_repeat" => ->{ @mpd.repeat },
      "toggle_single" => ->{ @mpd.single },
      "toggle_consume" => ->{ @mpd.consume },
      "toggle_random" => ->{ @mpd.random },
      "volume_up" => ->{ @mpd.increase_volume },
      "volume_down" => ->{ @mpd.decrease_volume },
      "seek_forward" => ->{ @mpd.seek_forward },
      "seek_backward" => ->{ @mpd.seek_backward },
      "queue_remove" => ->{ @windows[:queue].as(Peridot::UI::QueueWindow).remove },
      "queue_clear" => ->{ @windows[:queue].as(Peridot::UI::QueueWindow).clear },
      "filter" => filter_command,
      "unfilter" => unfilter_command
     }.as(Hash(String, Proc(Nil)))
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
    @filtered = false
  end

  def initialize(@title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32), lines : Array(String))
    @container = Peridot::TContainer.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
    @border = Border.new(container)
    @container << @border
    @offset = 0
    add_title
    @lines = lines
    @selected_line = -1
    @filtered = false
  end

  def resize(dimensions)
    @container.pivot = Position.new(dimensions[:x], dimensions[:y])
    @container.width = dimensions[:w]
    @container.height = dimensions[:h]
    @border = Border.new(container)
    self.draw
  end

  def draw
    @container.empty
    @container << @border
    add_title
    unless @lines.empty?
      if @selected_line >= 0
        write_lines(@lines, @selected_line)
      else
        write_lines(@lines)
      end
    end
  end

  # Note: This will truncate the lines if they extend beyond the containers boundary
  def write_line(text : String, line : Int32)
    text.chars.each.with_index do |char, column|
      break if column == @container.width - 2
      @container << Cell.new(char, Position.new(column + 1, line))
    end
  end

  # Writes the line using the given colors
  def write_line(text : String, line : Int32, fg : Int32, bg : Int32)
    text.chars.each.with_index do |char, column|
      break if column == @container.width - 2
      @container << Cell.new(char, Position.new(column + 1, line), fg, bg)
    end
  end

  # Note: This will truncate the lines if they extend beyond the containers boundary
  def write_lines(lines : Array(String))
    lines.each.with_index do |line, row|
      break if row == @container.height - 2
      write_line(line, row + 1)
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
      break if row == max_height
      if row == selected_index
        write_line(line, row + 1, CONFIG.colors["foreground_select"], CONFIG.colors["background_select"])
      else
        write_line(line, row + 1)
      end
    end
  end

  def select
    @border.foreground = CONFIG.colors["foreground_select"]
  end

  def deselect
    @border.foreground = CONFIG.colors["foreground"]
  end

  # Defined Here to be overriden in child classes
  def update
  end

  # Defined Here to be overriden in child classes
  def play
  end

  def add
  end

  def filter(arg)
  end

  def unfilter
  end

  def current_line : String
    @lines[@selected_line]
  end

  def filtered?
    @filtered
  end

  private def add_title
    write_line(@title, 0)
  end

  private def format_line_margin(start_string : String, end_string : String, width : Int32) : String
      margin_length = (width - (start_string.size + end_string.size) - 2)
      margin = (margin_length < 0) ? " " : " " * margin_length
      (start_string + margin + end_string).rstrip
  end
end

class Peridot::UI::StatusWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    super(formatted_status, dimensions, formatted_stats)
  end

  def update
    @title = formatted_status
    @lines = formatted_stats
    draw
  end

  private def formatted_status : String
    sprintf("%s (Random: %s | Repeat: %s | Consume: %s  | Single: %s | Volume: %s%%)",
      (state = @mpd.state) ? state.capitalize : "",
      @mpd.random? ? "On" : "Off",
      @mpd.repeat? ? "On" : "Off",
      @mpd.consume? ? "On" : "Off",
      @mpd.single? ? "On" : "Off",
      @mpd.volume,
    )
  end

  private def formatted_stats : Array(String)
    if current_song = @mpd.current_song
      [current_song.title, "#{current_song.album}, #{current_song.artist}", formatted_time]
    else
      ["", "", ""]
    end
  end

  private def formatted_time : String
    total_time = @mpd.total_time
    elapsed_time = @mpd.elapsed_time
    diff_time = total_time - elapsed_time
    total_minutes, total_seconds = total_time.divmod(60)
    elapsed_minutes, elapsed_seconds = elapsed_time.divmod(60)
    diff_minutes, diff_seconds = diff_time.divmod(60)
    sprintf("%s:%s/%s:%s (-%s:%s)",
            elapsed_minutes,
            (elapsed_seconds < 10) ? "0#{elapsed_seconds}" : elapsed_seconds,
            total_minutes,
            (total_seconds < 10) ? "0#{total_seconds}" : total_seconds,
            diff_minutes,
            (diff_seconds < 10) ? "0#{diff_seconds}" : diff_seconds,)
  end
end

class Peridot::UI::QueueWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    super("Queue (#{@mpd.queue_length} Songs)", @dimensions, formatted_songs)
  end

  def play
    @mpd.play(UInt32.new(@selected_line))
  end

  def remove : Void
    @mpd.queue_delete(UInt32.new(@selected_line))

    # Move up if deleting the last item in the queue
    @selected_line -= 1 unless @selected_line.zero?
  end

  def clear : Void
    @mpd.queue_clear
    @selected_line = 0
  end

  def update
    @lines = formatted_songs
    @title = "Queue (#{@mpd.queue_length} Songs)"
    draw
  end

  private def formatted_songs
    @mpd.queue_songs.map { |x| format_line_margin("#{x.artist} - #{x.title}", "#{x.album}", @dimensions[:w]) }
  end
end

class Peridot::UI::SongWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @songs = @mpd.songs.sort { |a, b| a.title <=> b.title }.as(Array(Peridot::MPD::Library::Song))
    super("Songs", @dimensions, formatted_songs)
  end

  def play
    self.add
    @mpd.play(UInt32.new(@mpd.queue_length - 1))
  end

  def add
    @mpd.queue_add(@songs[@selected_line].uri)
  end

  def filter(album_name : String)
    @filtered = true
    @selected_line = 0
    @songs = @songs.select { |x| x.album == album_name }
    @lines = formatted_songs
    @title = "Songs (#{album_name})"
    draw
  end

  def unfilter
    @filtered = false
    @selected_line = 0
    @songs = @mpd.songs.sort { |a, b| a.title <=> b.title }.as(Array(Peridot::MPD::Library::Song))
    @lines = formatted_songs
    @title = "Songs"
    draw
  end

  private def formatted_songs
    @songs.map { |x| format_line_margin("#{x.title}", "#{x.album}, #{x.artist}", @dimensions[:w]) }
  end
end

class Peridot::UI::AlbumWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @albums = @mpd.albums.sort { |a, b| a.name <=> b.name }.as(Array(Peridot::MPD::Library::Album))
    super("Albums", @dimensions, formatted_albums)
  end

  def play
    songs = @albums[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
    # Play the first song
    @mpd.play(UInt32.new(@mpd.queue_length - (songs.size)))
  end

  def add
    songs = @albums[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
  end

  def filter(artist_name : String)
    @filtered = true
    @selected_line = 0
    @albums = @albums.select { |x| x.artists.map(&.name).includes?(artist_name) }
    @lines = formatted_albums
    @title = "Albums (#{artist_name})"
    draw
  end

  def unfilter
    @filtered = false
    @selected_line = 0
    @albums = @mpd.albums.sort { |a, b| a.name <=> b.name }.as(Array(Peridot::MPD::Library::Album))
    @lines = formatted_albums
    @title = "Albums"
    draw
  end

  private def formatted_albums
    @albums.map { |x| format_line_margin("#{x.name}", "", @dimensions[:w]) }
  end
end

class Peridot::UI::ArtistWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @artists = @mpd.artists.sort { |a, b| a.name <=> b.name }.as(Array(Peridot::MPD::Library::Artist))
    super("Artists", @dimensions, formatted_artists)
  end

  def play
    songs = @artists[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
    # Play the first song
    @mpd.play(@mpd.queue_length - (songs.size))
  end

  def add
    songs = @artists[@selected_line].songs
    songs.each { |x| @mpd.queue_add(x.uri) }
  end

  private def formatted_artists
    @artists.map { |x| format_line_margin("#{x.name}", "", @dimensions[:w]) }
  end
end

class Peridot::UI::PlaylistWindow < Peridot::UI::Window
  def initialize(@mpd : MpdClient, @dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
    @playlists = @mpd.playlists.as(Array(String))
    super("Playlists", @dimensions, formatted_playlist)
  end

  def play
    before_length = @mpd.queue_length
    self.add
    after_length = @mpd.queue_length
    playlist_length = after_length - before_length
    @mpd.play(UInt32.new(after_length - playlist_length))
  end

  def add
    playlist_name = @lines[@selected_line]
    @mpd.playlist_load(playlist_name)
  end

  private def formatted_playlist
    @playlists.map do |x|
      name = Path[x].basename
      ext = Path[x].extension
      name.gsub(/#{ext}/, "")
    end
  end
end
