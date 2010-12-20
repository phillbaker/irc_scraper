require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'page_detective.rb'

require 'time'

class MediaWikiApiTest < Test::Unit::TestCase
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
    @detective = PageDetective.new(@db)
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
    assert_equal(["391225974",1287318134], [pageinfo[0], pageinfo[1]])
  end

  def test_investigate
    @detective.setup_table()
    rownum = @detective.investigate(@info)
    assert_equal(1.to_s, rownum.to_s)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @detective.setup_table()
    end
  end

end