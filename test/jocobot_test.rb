require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'jocobot.rb'

class JoCoBotTest < Test::Unit::TestCase
  
  def setup
    @bot = JoCoBot.new
    @bot.register Proc.new { |message| @said << message }, Proc.new { |action| @done << action } 
    @said = []
    @done = []
  end
  
  def test_instantiation
    assert @bot
  end
  
  def test_name
    assert_equal BOT_NAME, @bot.name
  end
  
  def test_unknown_song_no_punctuation_or_capitalization
    @bot.hear "#{BOT_NAME.downcase} sing foobar"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_no_capitalization
    @bot.hear "#{BOT_NAME.downcase}, sing foobar"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song
    @bot.hear "#{BOT_NAME}, sing Foobar."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_exclamation
    @bot.hear "#{BOT_NAME}! Sing Foobar!"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_colon
    @bot.hear "#{BOT_NAME}: sing Foobar."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_period
    @bot.hear "#{BOT_NAME}. Sing Foobar."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_no_punctuation_or_capitalization_middle_salutation
    @bot.hear "hey #{BOT_NAME.downcase} sing foobar"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_no_capitalization_middle_salutation
    @bot.hear "hey #{BOT_NAME.downcase}, sing foobar"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_middle_salutation
    @bot.hear "Hey, #{BOT_NAME}, sing Foobar."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_exclamation_middle_salutation
    @bot.hear "Hey #{BOT_NAME}! Sing Foobar!"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_unknown_song_colon_middle_salutation
    @bot.hear "Dear #{BOT_NAME}: sing Foobar."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_no_punctuation_or_capitalization_ending_salutation
    @bot.hear "sing foobar #{BOT_NAME.downcase}"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_no_capitalization_ending_salutation
    @bot.hear "sing foobar, #{BOT_NAME.downcase}"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_ending_salutation
    @bot.hear "Sing Foobar, #{BOT_NAME}."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_exclamation_ending_salutation
    @bot.hear "Sing Foobar! #{BOT_NAME}!"
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end

  def test_unknown_song_period
    @bot.hear "Sing Foobar. #{BOT_NAME}."
    assert_equal UNKNOWN_SONG_RESPONSE, @said.first
  end
  
  def test_no_last_song
    @bot.hear "#{BOT_NAME.downcase} what is that song called?"
    assert_equal NO_NAME_OF_SONG_RESPONSE, @said.last
  end
  
  def test_no_song_to_stop
    @bot.hear "#{BOT_NAME.downcase} stop singing"
    assert_equal 0, @said.length
  end
  
  def test_sing_random_song_and_stop_singing
    @bot.hear "#{BOT_NAME.downcase} sing"
    listen_to_song
    @said.each do |line|
      assert_equal String, line.class
    end
    before_length = @said.length
    @bot.hear "#{BOT_NAME.downcase} stop"
    sleep 5
    assert_equal before_length, @said.length
    assert_equal STOPPING_ACTION, @done.last
  end
  
  def test_sing_requested_song_monkey_stop_and_name_of_song
    song = @bot.songs.random_song
    @bot.hear "#{BOT_NAME.downcase} sing #{song.title}"
    listen_to_song
    assert_equal STARTING_ACTION, @done.first
    song.beginning
    @said.each do |line|
      assert_equal song.next_line, line
    end
    before_length = @said.length
    @bot.hear "something something monkey something else"
    sleep 5
    assert_equal before_length, @said.length
    assert MONKEY_ACTIONS.inject(false) { |boolean, action| boolean || @done.include?(action) }
    assert_equal STOPPING_ACTION, @done.last
    @bot.hear "#{BOT_NAME.downcase} what is the name of that song"
    assert_equal "#{NAME_OF_SONG_RESPONSE} \"#{song.title}.\"", @said.last
    @said = []
    @bot.hear "#{BOT_NAME.downcase} what is that song called?"
    assert_equal "#{NAME_OF_SONG_RESPONSE} \"#{song.title}.\"", @said.last
  end
  
  private
  
  def listen_to_song
    timer = 0
    until @said.length > 2 || timer > 30
      sleep 1
      timer = timer + 1
    end
    assert @said.length > 2
  end
  
end