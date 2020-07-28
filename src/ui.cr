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
    getter container : Termbox::Container

    def initialize(title : String, dimensions : NamedTuple(x: Int32, y: Int32, w: Int32, h: Int32))
      @container = Container.new(Position.new(dimensions[:x], dimensions[:y]), dimensions[:w], dimensions[:h])
      @border = Border.new(container)
      @container << @border
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
      lines.each.with_index do |line, row|
        if row == selected_index
          write_line(line, row + 1, 2, 0)
        else
          write_line(line, row + 1)
        end
        break if row + 1 == @container.height - 2
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
          write_line((" " * (@container.width - 1)), row + 1)
          break if row + 1 == @container.height - 2
      end
   end
  end
end
