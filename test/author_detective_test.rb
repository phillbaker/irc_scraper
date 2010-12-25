require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'author_detective.rb'

require 'time'

class AuthorDetectiveTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia ( id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text)')
    @clazz = AuthorDetective
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

   @info2 = [1,
      'Amar Ben Belgacem',
      'M',
      '392473902',
      '391225974',
      'Alice',
      '+226',
      Time.parse('2010-02-10T22:17:39Z'),
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
  end
  
  def test_find_account_history_create_life_groups_block
    account_history = @detective.find_account_history(@info)
    assert_equal([1233505878, 32334381, "rollbacker", 0], [account_history[0], account_history[1], account_history[10], account_history[11]])
  end
  
  def test_find_account_edit_bucket
    #so all of these values are going to change (upward only in theory...we'll test against known values)
    #all these values should change (as time goes on, they're all time dependent!)
    account_history = @detective.find_account_history(@info)
    assert_operator 10, :<=, account_history[2], "total edit count"
    assert_operator 0, :<=, account_history[3], "second ago"
    assert_operator 0, :<=, account_history[4], "minute"
    assert_operator 0, :<=, account_history[5], "hour"
    assert_operator 0, :<=, account_history[6], "day"
    assert_operator 0, :<=, account_history[7], "week"
    assert_operator 0, :<=, account_history[8], "month"
    assert_operator 10, :<=, account_history[9], "year"
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

  def test_block_info
    account_history =  @detective.find_account_history(@info2)
    assert_equal([1, 764932, "Picaroon", nil, "[[Wikipedia:Requests for checkuser/Case/W. Frank|sockpuppet of W. Frank]]"], [account_history[11], account_history[12], account_history[13], account_history[15], account_history[16]])
  end

  def test_non_existent_author_info
    res = @detective.find_account_history([1,
      'Saoula',
      '',
      '403706560',
      '403544118',
      '41.105.23.56',
      '+33',
      Time.parse('2010-02-10T22:17:39Z'),
      ""
    ])
    assert_equal(['-', 0, 1, 0, 0, 0, 0, 0, 0, 0, "", 0, nil], res)
  end
end