require 'helper'

class TestAlbum < Test::Unit::TestCase
  context "an album with territories" do
    setup do
      @album = MetaSpotify::Album.new('name' => 'test', 'availability' => { 'territories' => 'DE' })
      @worldwide_album = MetaSpotify::Album.new('name' => 'test', 'availability' => { 'territories' => 'worldwide' })
    end
    should "be available in DE" do
      assert @album.is_available_in?('DE')
    end
    should "not be available in UK" do
      assert @album.is_not_available_in?('UK')
    end
    should "be available anywhere" do
      assert @worldwide_album.is_available_in?('UK')
    end
  end
  
  context "searching for an album name" do
    setup do
      FakeWeb.register_uri(:get,
                           "http://ws.spotify.com/search/1/album?q=foo",
                           :body => fixture_file("album_search.xml"))
      @results = MetaSpotify::Album.search('foo')
    end
    should "return a list of results and search meta" do
      assert_kind_of Array, @results[:albums]
      assert_kind_of MetaSpotify::Album, @results[:albums].first
      assert_equal "Foo Foo", @results[:albums].first.name
      assert_equal 0.29921, @results[:albums].first.popularity
      assert_equal 1, @results[:query][:start_page]
      assert_equal 'request', @results[:query][:role]
      assert_equal "foo", @results[:query][:search_terms]
      assert_equal 100, @results[:items_per_page]
      assert_equal 0, @results[:start_index]
      assert_equal 6, @results[:total_results]
    end
  end
  
  context "looking up a album" do
    setup do
      FakeWeb.register_uri(:get,
                           "http://ws.spotify.com/lookup/1/?uri=#{CGI.escape ALBUM_URI}",
                           :body => fixture_file("album.xml"))
      @result = MetaSpotify::Album.lookup(ALBUM_URI)
    end
    should "fetch an album and return an album object" do
      assert_kind_of MetaSpotify::Album, @result
      assert_equal "Remedy", @result.name
      assert_equal ALBUM_URI, @result.uri
      assert_equal "1999", @result.released
      assert_equal "634904012922", @result.upc
      assert_equal "3a3685aa-9c4d-42f8-a401-e34a89494041", @result.musicbrainz_id
      assert_equal "http://www.allmusic.com/cg/amg.dll?p=amg&sql=10:dpfixqtkld0e", @result.allmusic_uri
    end
    should "create an artist object for that album" do
      assert_kind_of Array, @result.artists
      assert_kind_of MetaSpotify::Artist, @result.artists.first
      assert_equal "Basement Jaxx", @result.artists.first.name
      assert_equal "spotify:artist:4YrKBkKSVeqDamzBPWVnSJ", @result.artists.first.uri
    end
    should "fail trying to look up an track" do
      assert_raises MetaSpotify::URIError do
        MetaSpotify::Album.lookup(TRACK_URI)
      end
    end
  end
  context "looking up an album with extra details" do
    setup do
      FakeWeb.register_uri(:get,
                           "http://ws.spotify.com/lookup/1/?extras=trackdetail&uri=#{CGI.escape ALBUM_URI}",
                           :body => fixture_file('album_with_trackdetail.xml'))
      @result = MetaSpotify::Album.lookup(ALBUM_URI, :extras => 'trackdetail')
    end
    
    should "fetch an album and return an object with more detailed track information" do
      assert_kind_of MetaSpotify::Album, @result
      assert_kind_of MetaSpotify::Track, @result.tracks.first
      assert_equal 'Rendez-vu', @result.tracks.first.name
    end
  end
end