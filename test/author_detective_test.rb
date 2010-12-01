require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'author_detective.rb'

require 'time'

class MediaWikiApiTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia (id integer primary key autoincrement, article_name varchar(128) not null, desc varchar(8), url varchar(256), user varchar(64), byte_diff integer, ts timestamp(20), description text )')
    @detective = AuthorDetective.new(@db)
    @info = [1,
      'Amar Ben Belgacem',
      'M',
      'http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974',
      'SD5',
      '+226',
      Time.parse('2010-02-10T22:17:39Z'),
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
  end
  
  def test_find_account_history
    account_history = @detective.find_account_history(@info)
    assert_equal([], account_history)
  end
  
  def test_investigate
    @detective.setup_table()
    rownum = @detective.investigate(@info)
    assert_equal(1, rownum)
  end
end