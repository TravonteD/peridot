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

  describe "#play" do
    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::QueueWindow.new(client, dimensions)
      window.selected_line = 1

      window.play

      expected = {true, 1}
      client.@played.should eq expected
    end
  end

  describe "#remove" do
    describe "when the selected line is last in the queue" do
      it "moves to the the new last item" do
        client = DummyMpdClient.new(queue_length: 2)
        dimensions = {x: 1, y: 1, w: 1, h: 1}
        window = Peridot::UI::QueueWindow.new(client, dimensions)
        window.selected_line = 1

        window.remove

        window.selected_line.should eq 0
      end
    end
  end

  describe "clear" do
    it "empties the queue" do
      client = DummyMpdClient.new(queue_length: 2)
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::QueueWindow.new(client, dimensions)
      window.selected_line = 1

      window.clear

      window.selected_line.should eq 0
      client.@queue_length.should eq 0
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

  describe "#play" do
    it "adds the selected song to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, "test_uri"}
      client.@added.should eq expected
      client.@queue_length.should eq 1
    end

    it "plays the selected song" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, 0}
      client.@played.should eq expected
    end
  end

  describe "#add" do
    it "adds the selected song to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.add

      expected = {true, "test_uri"}
      client.@added.should eq expected
      client.@queue_length.should eq 1
    end
  end

  describe "#filter & #unfilter" do
    it "filters the songs based on the given album name" do
      song1 = Peridot::MPD::Library::Song.new("song1", "", "test_album", "")
      song2 = Peridot::MPD::Library::Song.new("song2", "", "", "")
      song3 = Peridot::MPD::Library::Song.new("song3", "", "test_album", "")
      song4 = Peridot::MPD::Library::Song.new("song4", "", "", "")
      client = DummyMpdClient.new(songs: [song1, song2, song3, song4])
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::SongWindow.new(client, dimensions)
      window.selected_line = 0

      window.filter("test_album")

      window.@songs.should eq [song1, song3]
      window.filtered?.should be_true

      window.unfilter

      window.@songs.should eq [song1, song2, song3, song4]
      window.filtered?.should be_false
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

  describe "#play" do
    it "adds the selected albums songs to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::AlbumWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      client.@queue_length.should eq 2
    end

    it "plays the first song in the album" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::AlbumWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, 0}
      client.@played.should eq expected
    end
  end

  describe "#add" do
    it "adds the selected albums songs to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::AlbumWindow.new(client, dimensions)
      window.selected_line = 0

      window.add

      client.@queue_length.should eq 2
    end
  end

  describe "#current_line" do
    it "returns the name of the selected album" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::AlbumWindow.new(client, dimensions)
      window.selected_line = 0

      window.current_line.should eq "test_album"
    end
  end

  describe "#filter & #unfilter" do
    it "filters the songs based on the given album name" do
      artist1 = Peridot::MPD::Library::Artist.new("artist1")
      artist2 = Peridot::MPD::Library::Artist.new("artist2")
      album1 = Peridot::MPD::Library::Album.new("album1")
      album2 = Peridot::MPD::Library::Album.new("album2")
      album3 = Peridot::MPD::Library::Album.new("album3")
      album4 = Peridot::MPD::Library::Album.new("album4")
      album1.artists << artist1
      album2.artists << artist2
      album3.artists << artist1
      album4.artists << artist2
      client = DummyMpdClient.new(albums: [album1, album2, album3, album4])
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::AlbumWindow.new(client, dimensions)
      window.selected_line = 0

      window.filter("artist1")

      window.@albums.should eq [album1, album3]
      window.filtered?.should be_true

      window.unfilter

      window.@albums.should eq [album1, album2, album3, album4]
      window.filtered?.should be_false
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

  describe "#play" do
    it "adds the selected artists songs to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::ArtistWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      client.@queue_length.should eq 2
    end

    it "plays the first song that was added" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::ArtistWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, 0}
      client.@played.should eq expected
    end
  end

  describe "#add" do
    it "adds the selected artists songs to the queue" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::ArtistWindow.new(client, dimensions)
      window.selected_line = 0

      window.add

      client.@queue_length.should eq 2
    end
  end
  describe "#current_line" do
    it "returns the name of the selected artist" do
      client = DummyMpdClient.new
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::ArtistWindow.new(client, dimensions)
      window.selected_line = 0

      window.current_line.should eq "test_artist"
    end
  end
end

describe Peridot::UI::PlaylistWindow do
  it "displays the playlists in the library properly formatted" do
    client = DummyMpdClient.new(playlists: ["playlist/test_playlist.m3u", "playlist/test_playlist.m3u"])
    dimensions = {x: 1, y: 1, w: 1, h: 1}
    window = Peridot::UI::PlaylistWindow.new(client, dimensions)

    window.@lines.should eq ["test_playlist", "test_playlist"]
  end

  describe "#play" do
    it "adds the selected artists songs to the queue" do
      client = DummyMpdClient.new(playlists: ["test_playlist0", "test_playlist1"])
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::PlaylistWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, "test_playlist0"}
      client.@playlist_loaded.should eq expected
    end

    it "plays the first song in the playlist" do
      client = DummyMpdClient.new(playlists: ["test_playlist0", "test_playlist1"])
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::PlaylistWindow.new(client, dimensions)
      window.selected_line = 0

      window.play

      expected = {true, 0}
      client.@played.should eq expected
    end
  end

  describe "#add" do
    it "adds the selected artists songs to the queue" do
      client = DummyMpdClient.new(playlists: ["test_playlist0", "test_playlist1"])
      dimensions = {x: 1, y: 1, w: 1, h: 1}
      window = Peridot::UI::PlaylistWindow.new(client, dimensions)
      window.selected_line = 0

      window.add

      expected = {true, "test_playlist0"}
      client.@playlist_loaded.should eq expected
    end
  end
end
