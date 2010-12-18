require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'external_link_detective.rb'

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
    @detective = ExternalLinkDetective.new(@db)
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

    @info2 = [2,
      'Vladimir Guerrero',
      'M',
      '392473934',
      '392337290',
      'Briskbaby',
      '+290',
      Time.parse('2010-02-10T22:17:39Z'),
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
  end
  
  def test_find_link_info
    linkinfo = @detective.find_link_info(@info2)
    assert_equal([10], [linkinfo.length])
    arr = Array.new(linkinfo.length)
    i = 0
    linkinfo.each do |entry|
      arr[i]= entry["link"]
      i=i+1
    end
    		  
    assert_equal(["http://baseballprospectus.com/article.php?articleid=9803",
 "http://blog.seattlepi.com/seattlesports/archives/169131.asp?from=blog_last3",
 "http://insider.espn.go.com/espn/blog/index?entryID=4558550&name=arangure_jorge_jr&addata=2009_insdr_mod_mlb_xxx_xxx&action=login&appRedirect=http:%2f%2finsider.espn.go.com%2fespn%2fblog%2findex%3fentryID=4558550&name=arangure_jorge_jr&addata=2009_insdr_mod_mlb_xxx_xxx",
 "http://latimesblogs.latimes.com/sports_blog/2009/08/angels-guerrero-slams-400th-career-home-run-.html",
 "http://minors.baseball-reference.com/players.cgi?pid=5922",
 "http://mlb.mlb.com/team/player.jsp?player_id=115223",
 "http://sports.espn.go.com/mlb/columns/story?columnist=stark_jayson&page=rumblings/080424",
 "http://sports.espn.go.com/mlb/news/story?id=1706614",
 "http://sports.espn.go.com/mlb/players/stats?playerId=3576",
 "http://sports.espn.go.com/mlb/recap?gameId=301022113"], arr)
  end

  def test_investigate
    @detective.setup_table()
    rownum = @detective.investigate(@info)
    assert_equal(1, rownum)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @detective.setup_table()
    end
  end

end