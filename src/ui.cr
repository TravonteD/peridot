require "termbox"

include Termbox

module Peridot::UI
  # Creates a new window, sets up colors
  # and adds a border
  def self.init
    w = Termbox::Window.new
    w.set_output_mode(OUTPUT_NORMAL)
    w.set_primary_colors(8, 0)
    w.clear
    w << Border.new(w)
    w.render
    w
  end

  # Represents a termbox container used as a window within the UI
  struct Window
    property :title
    getter :container

    def initialize(title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
      @container = Container.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
      @container << Border.new(container)
      add_title(title)
    end

    def write_line(text : String, line : Int32)
      text.chars.each.with_index do |char, column|
        @container << Cell.new(char, Position.new(column + 1, line))
        column += 1
      end
    end

    # Note: This will truncate the lines if they extend beyond the containers boundary
    def write_lines(lines : Array(String))
      lines.each.with_index do |line, row|
        write_line(line, row + 1)
        break if row + 1 == @container.height - 2
      end
    end

    private def add_title(title : String)
      write_line(title, 0)
    end
  end
end
