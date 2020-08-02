require "termbox"

include Termbox

module UIClient
  abstract def empty
  abstract def clear
  abstract def clear
  abstract def empty
  abstract def render
  abstract def poll
  abstract def shutdown
  abstract def set_output_mode(mode : Int32)
  abstract def set_primary_colors(fg : Int32, bg : Int32)
  abstract def clear
  abstract def width
  abstract def height
end

# Extends a termbox window to allow for element clearing
class Peridot::TWindow < Termbox::Window
  include UIClient

  def initialize
    super
  end

  def empty
    @elements = [] of Element
  end
end

class Peridot::TBorder < Termbox::Border
  def initialize(window : UIClient)
    super(window)
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
