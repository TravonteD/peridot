require "./spec_helper"

describe Peridot::UI do
  it "initializes all of the windows" do
    ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
    expected = [:library, :queue, :status, :playlist, :album, :artist, :song].sort

    ui.@windows.keys.sort.should eq expected
  end

  it "sets the primary window to :queue" do
    ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)

    ui.@primary_window.should eq :queue
  end

  describe "#move_down" do
    it "increments the current windows selected line" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
      ui.select_window(:library)
      line = ui.@windows[:library].@selected_line

      ui.move_down

      ui.@windows[:library].@selected_line.should eq line + 1
    end
  end

  describe "#move_up" do
    it "decrements the current windows selected line" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)
      ui.select_window(:library)

      ui.move_down

      ui.@windows[:library].@selected_line.should eq 1

      ui.move_up

      ui.@windows[:library].@selected_line.should eq 0
    end
  end

  describe "#select_window" do
    it "makes the given window the current one" do
      ui = Peridot::UI.new(DummyMpdClient.new, DummyUIClient.new)

      ui.select_window(:library)

      ui.@current_window.should eq :library
    end
  end
end

describe Peridot::UI::StatusWindow do
  it "properly formats the title" do
    client = DummyMpdClient.new(state: "Stopped")
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    window = Peridot::UI::StatusWindow.new(client, dimensions)
    expected = "Stopped (Random: Off | Repeat: Off | Consume: Off  | Single: Off | Volume: 0%)"

    window.@title.should eq expected
  end

  it "shows the now playing information" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_title", "test_album, test_artist", "0:00/0:00 (-0:00)"]
    window = Peridot::UI::StatusWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  it "shows the time information" do
    one_minute = UInt32.new(60)
    three_minutes = one_minute * 3
    client = DummyMpdClient.new(total_time: three_minutes, elapsed_time: one_minute)
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = "1:00/3:00 (-2:00)"
    window = Peridot::UI::StatusWindow.new(client, dimensions)

    window.@lines.last.should eq expected
  end
end

describe Peridot::UI::QueueWindow do
  it "displays the length of the queue in the title" do
    client = DummyMpdClient.new(queue_length: 5)
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = "Queue (5 Songs)"
    window = Peridot::UI::QueueWindow.new(client, dimensions)

    window.@title.should eq expected
  end

  it "displays the songs in the queue" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_artist - test_title test_album"]
    window = Peridot::UI::QueueWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::QueueWindow.new(client, dimensions)
      window.selected_line = 1

      window.action

      expected = {true, 1}
      client.@played.should eq expected
    end
  end
end

describe Peridot::UI::SongWindow do
  it "displays the songs in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_title test_album, test_artist"]
    window = Peridot::UI::SongWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
    it "adds the selected song to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.action

      expected = {true, "test_uri"}
      client.@added.should eq expected
      client.@queue_length.should eq 1
    end

    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.action

      expected = {true, 0}
      client.@played.should eq expected
    end
  end
end

describe Peridot::UI::AlbumWindow do
  it "displays the albums in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_album"]
    window = Peridot::UI::AlbumWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
      it "adds the selected albums songs to the queue" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::AlbumWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        client.@queue_length.should eq 2
      end

      it "plays the first song in the album" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::AlbumWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        expected = {true, 0}
        client.@played.should eq expected
      end
  end
end

describe Peridot::UI::ArtistWindow do
  it "displays the artists in the library" do
    client = DummyMpdClient.new
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    expected = ["test_artist"]
    window = Peridot::UI::ArtistWindow.new(client, dimensions)

    window.@lines.should eq expected
  end

  describe "#action" do
      it "adds the selected artists songs to the queue" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::ArtistWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        client.@queue_length.should eq 2
      end

      it "plays the first song that was added" do
        client = DummyMpdClient.new
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::ArtistWindow.new(client, dimensions)
        window.selected_line = 0

        window.action

        expected = {true, 0}
        client.@played.should eq expected
      end
  end
end
