require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'songs.rb'

class SongsTest < Test::Unit::TestCase
  
  def setup
    @songs = Songs.new
  end
  
  def test_implicit_instantiation
    assert @songs
  end
  
  def test_explicit_instantiation
    assert Songs.new('../lib/lyrics/')
  end
  
  def test_list
    assert @songs.list
    assert @songs.list.kind_of? Array
    assert !@songs.list.empty?
    assert @songs.list.first.kind_of? String
  end
  
  def test_song
    titles = ["Always the Moon", "Bozo's Lament", "Dance, Soterios Johnson, Dance", "De-Evolving", "The Future Soon", "Mr. Fancy Pants", "Re: Your Brains", "SkyMall", "That Spells DNA", "Todd the T1000", "When I'm 25 or 64"]
    titles.each do |title|
      assert @songs.song(title)
      assert @songs.song(title).kind_of? Song
    end
  end
  
  def test_no_song
    assert @songs.song("Foobar").nil?
  end
  
  def test_random_song
    assert @songs.random_song
    assert @songs.random_song.kind_of? Song
  end

end