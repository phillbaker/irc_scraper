require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'enwiki_bot.rb'

class EnWikiBotTest < Test::Unit::TestCase
  
  def setup
    @db = SQLite3::Database.new(":memory:")
    @bot = EnWikiBot.new('server', 6667, 'channel', 'password', 'test_bot', @db)
    #@bot.register Proc.new { |message| @said << message }, Proc.new { |action| @done << action } 
    #@said = []
    #@done = []
  end
  
  def test_instantiation
    assert @bot
    #assert_equal("server_channel", @bot.table_name)
    #assert_equal(@bot.db, @db)
  end
  
  def test_name
    assert_equal "test_bot", @bot.name
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
    assert_equal("\nid\narticle_name\ndesc\nrevision_id\nold_id\nuser\nbyte_diff\nts\ndescription", schema)
  end
  
  def test_db_open
    #TODO
  end
  
  def test_db_init
    #TODO
  end
  
  def test_db_write!
    res = @bot.db_write!(['Amar Ben Belgacem',
      'M',
      '392473902'.to_i,
      '391225974'.to_i,
      'SD5',
      '+226'.to_i,
      Time.now.to_i,
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ])
    assert_equal("1", res)
  end
  
  def test_should_store?
    #plain text version, without the true jobbies is not passed
    assert(!@bot.should_store?("[[Albert G. Brown]] http://en.wikipedia.org/w/index.php?diff=397580708&oldid=394909102 * Good Olfactory * (+53) added [[Category:Democratic Party United States Senators]] using [[WP:HC|HotCat]]"))
    #with invisibles below, is passed
    assert(@bot.should_store?("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]"))
  end
  
  def test_hear_calls
    #TODO needs to run in isolation
    assert(@bot.hear("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]"))
  end
  
  def test_store!
    res = @bot.store!("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]")
    expected = [1,
      'Amar Ben Belgacem',
      'M',
      392473902,
      391225974,
      'SD5',
      226,
      Time.now,
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
    expected.each_with_index do |o,i|
      assert_equal(
        o, res[i] #fails on the time one, should do that with a delta
      )
    end
    assert_equal(expected.size(), o.size())
  end
  
  def test_process_irc
    #set by Wikipedia
    #with invisibles:  14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]
    #[[Lighting]] http://en.wikipedia.org/w/index.php?diff=399864542&oldid=399863488 * Jacqui998 * (+165) /* Lamps */ 
    assert_equal(
      ['Amar Ben Belgacem',
        'M',
        '392473902',#'http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974',
        '391225974',
        'SD5',
        '+226',
        "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
      ], 
      @bot.process_irc("14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]")
    )
    assert_equal(
      ['Category talk:Miami Modern Architecture',
        'N',
        '403307402',
        '415103593',
        'Koavf',
        '+28',
        "tag using [[Project:AWB|AWB]]"
      ], 
      @bot.process_irc("14[[07Category talk:Miami Modern Architecture14]]4 N10 02http://en.wikipedia.org/w/index.php?oldid=403307402&rcid=415103593 5* 03Koavf 5* (+28) 10tag using [[Project:AWB|AWB]]")
    )
    
  end
  
end