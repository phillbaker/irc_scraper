require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'song.rb'

class SongTest < Test::Unit::TestCase
  
  def setup
    file = File.new("../lib/lyrics/futuresoon.txt", "r")
    @song = Song.new(file.read)
    file.close
  end
  
  def test_instantiation
    assert @song
    assert @song.kind_of? Song
  end
  
  def test_title
    assert_equal "The Future Soon", @song.title
  end
  
  def test_lyrics
    assert @song.lyrics
    assert @song.lyrics.kind_of? Array
    assert_equal 7, @song.lyrics.length
    assert @song.lyrics.first.kind_of? Array
    assert_equal 8, @song.lyrics.first.length
    assert @song.lyrics.first.first.kind_of? String
  end
  
  def test_first_three_lines
    assert_equal "Last week I left a note on Laura's desk", @song.next_line
    assert_equal "It said I love you, signed, anonymous friend", @song.next_line
    assert_equal "Turns out she's smarter than I thought she was", @song.next_line
  end
  
  def test_across_verse
    7.times { @song.next_line }
    assert_equal "When I'm living in my solar dome on a platform in space", @song.next_line
    assert_equal "'Cause it's gonna be the future soon", @song.next_line
  end
  
  def test_whole_song
    49.times { @song.next_line }
    assert @song.has_more_lines?
    assert_equal "And when my heart is breaking I can close my eyes and it's already here", @song.next_line
    assert !@song.has_more_lines?
    assert_equal nil, @song.next_line
  end
  
  def test_random_verse
    first_lines = ["Last week I left a note on Laura's desk", "'Cause it's gonna be the future soon", "I'll probably be some kind of scientist", "Here on Earth they'll wonder", "I'll see her standing by the monorail", "Well it's gonna be the future soon"]
    @song.random_verse
    assert equal_one(first_lines, @song.next_line)
  end
  
  def test_random_line
    @song.random_line
    assert @song.next_line 
  end
  
  def test_beginning
    5.times { @song.next_line }
    @song.beginning
    assert_equal "Last week I left a note on Laura's desk", @song.next_line
    10.times { @song.next_line }
    @song.beginning
    assert_equal "Last week I left a note on Laura's desk", @song.next_line
    @song.random_verse
    @song.beginning
    assert_equal "Last week I left a note on Laura's desk", @song.next_line
    @song.random_line
    @song.beginning
    assert_equal "Last week I left a note on Laura's desk", @song.next_line
  end
  
  private
  
  def equal_one(array, actual)
    array.inject(false) do |boolean, current|
      boolean || current == actual
    end
  end
  
end