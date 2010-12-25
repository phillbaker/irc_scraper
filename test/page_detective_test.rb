require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'page_detective.rb'

require 'time'

class PageDetectiveTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia (
      id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text)')
    @clazz = PageDetective
    @detective = @clazz.new(@db)
    @info = [1,
      'Amar Ben Belgacem',
      'M',
      '392473902',
      '391225974',
      'SD5',
      '+226',
      Time.parse('2010-02-10T22:17:39Z'),
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
  end
  
  def test_find_page_info
    pageinfo = @detective.find_page_history(@info)
    assert_equal(["391225974", "1287318134"], [pageinfo[0], pageinfo[1]])
  end

  def test_find_page_info_nils
    #always need to test badrevid when using oldid...
    pageinfo = @detective.find_page_history([2,
      'Category talk:Anime and manga articles with a missing image caption',
      '!N',
      '403743470',
      '415552604',
      'TheFarix',
      '+31',
      Time.parse('2010-02-10T22:17:39Z'),
      "[[WP:AES|←]]Created page with '{{WikiProject Anime and manga}}"])
    assert_equal(["-", "", "{{WikiProject Anime and manga}}", "0", "0"], pageinfo)
  end

  def test_find_page_info_sqlite
    @clazz.setup_table(@db)
    rownum = @detective.investigate([3,
      'Category talk:1830 in Canada',
      'N',
      '404100591',
      '415919731',
      'Koavf',
      '+2',
      Time.parse('2010-02-10T22:17:39Z'),
      "tag using [[Project:AWB|AWB]]"])
    assert_equal(1.to_s, rownum.to_s)
  end

  def test_investigate
    @clazz.setup_table(@db)
    rownum = @detective.investigate(@info)
    assert_equal(1.to_s, rownum.to_s)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @clazz.setup_table(@db)
    end
  end

end