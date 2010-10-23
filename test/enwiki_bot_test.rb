require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'enwiki_bot.rb'

class EnWikiBotTest < Test::Unit::TestCase
  
  def setup
    @bot = EnWikiBot.new('server', 6667, 'channel', 'password')
    #@bot.register Proc.new { |message| @said << message }, Proc.new { |action| @done << action } 
    #@said = []
    #@done = []
  end
  
  def test_instantiation
    assert @bot
  end
  
  def test_name
    assert_equal BOT_NAME, @bot.name
  end
  
  def test_db_exists?
    
  end
  
  def test_db_create!
    
  end
  
  def test_db_create_schema!
    @bot.db_create_schema! 'server_channel'
    schema = ''
    @bot.db.table_info('server_channel') do |row|
      schema += "\n" + row['name']
    end
    assert_equal(TABLE_SCHEMA_PREFIX + 'server_channel' + TABLE_SCHEMA_SUFFIX, schema)
  end
  
  def test_db_open
    
  end
  
  def test_db_init
    
  end
  
  def test_db_write!
    
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