require "./spec_helper"

describe Peridot::MPD::Library::Artist do
  it "takes a name" do
    artist = Peridot::MPD::Library::Artist.new("test_artist")

    result = artist.name

    result.should eq "test_artist"
  end

  describe "#albums" do
    it "returns an array of Peridot::MPD::Library::Album" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")

      result = artist.albums

      result.should be_a(Array(Peridot::MPD::Library::Album))
    end
  end

  describe "#songs" do
    it "returns an array of Peridot::MPD::Library::Song" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")

      result = artist.songs

      result.should be_a(Array(Peridot::MPD::Library::Song))
    end
  end
end

describe Peridot::MPD::Library::Album do
  it "has a name" do
    album = Peridot::MPD::Library::Album.new("test_album")

    result = album.name

    result.should eq "test_album"
  end

  describe "#artists" do
    it "returns an array of Peridot::MPD::Library::Artist" do
      artist = Peridot::MPD::Library::Artist.new("test_artist")
      album = Peridot::MPD::Library::Album.new("test_album")
      album.artists << artist

      result = album.artists

      result.should be_a(Array(Peridot::MPD::Library::Artist))
      result.should eq [artist]
    end
  end

  describe "#songs" do
    it "returns an array of Peridot::MPD::Library::Song" do
      album = Peridot::MPD::Library::Album.new("test_album")

      result = album.songs

      result.should be_a(Array(Peridot::MPD::Library::Song))
    end
  end
end

describe Peridot::MPD::Library::Song do
  it "has a uri" do
    song = Peridot::MPD::Library::Song.new("test_uri", "","","")

    result = song.uri

    result.should eq "test_uri"
  end

  it "has a album" do
    song = Peridot::MPD::Library::Song.new("", "","album","")

    result = song.album

    result.should eq "album"
  end

  it "has a artist" do
    song = Peridot::MPD::Library::Song.new("", "","","artist")

    result = song.artist

    result.should eq "artist"
  end
end
