require "./spec_helper"
require "../src/mpd"

describe Peridot::MPD::Library::Artist do
  describe ".new" do
    it "takes a name" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")

      result = artist.name

      result.should eq "test_artist"
    end
  end

  describe "#albums" do
    it "returns an array of Peridot::MPD::Library::Album" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")

      result = artist.albums

      result.should be_a(Array(Peridot::MPD::Library::Album))
    end
  end

  describe "#songs" do
    it "returns an array of Peridot::MPD::Song" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")

      result = artist.songs

      result.should be_a(Array(Peridot::MPD::Song))
    end
  end
end

describe Peridot::MPD::Library::Album do
  describe ".new" do
    it "takes a name" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")
      album = Peridot::MPD::Library::Album.new("test_album", artist)

      result = album.name

      result.should eq "test_album"
    end
  end

  describe "#artist" do
    it "returns an array of Peridot::MPD::Library::Album" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")
      album = Peridot::MPD::Library::Album.new("test_album", artist)

      result = album.artist

      result.should be_a(Peridot::MPD::Library::Artist)
      result.should eq artist
    end
  end

  describe "#songs" do
    it "returns an array of Peridot::MPD::Song" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")
      album = Peridot::MPD::Library::Album.new("test_album", artist)

      result = album.songs

      result.should be_a(Array(Peridot::MPD::Song))
    end
  end
end
