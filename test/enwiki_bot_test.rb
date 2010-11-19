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
    #TODO
  end
  
  def test_db_create!
    #TODO
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
    #TODO
  end
  
  def test_db_init
    #TODO
  end
  
  def test_db_write!
    #TODO
  end
  
  def test_should_store?
    #plain text version, without the true jobbies
    assert(!@bot.should_store?("[[Albert G. Brown]] http://en.wikipedia.org/w/index.php?diff=397580708&oldid=394909102 * Good Olfactory * (+53) added [[Category:Democratic Party United States Senators]] using [[WP:HC|HotCat]]"))
    #with invisibles below:
    assert(@bot.should_store?("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]"))
  end
  
  def test_hear_calls
    #TODO needs to run in isolation
    assert(@bot.hear("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]"))
  end
  
end