require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'external_link_detective.rb'

require 'time'

class ExternalLinkDetectiveTest < Test::Unit::TestCase
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
    @clazz = ExternalLinkDetective
    @queue = []
    @detective = @clazz.new(@queue)
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
    arr = []
    linkinfo.each do |entry|
      arr << entry["link"]
    end
    		  
    assert_equal([
      "http://baseballprospectus.com/article.php?articleid=9803",
      "http://blog.seattlepi.com/seattlesports/archives/169131.asp?from=blog_last3",
      "http://insider.espn.go.com/espn/blog/index?entryID=4558550&name=arangure_jorge_jr&addata=2009_insdr_mod_mlb_xxx_xxx&action=login&appRedirect=http:%2f%2finsider.espn.go.com%2fespn%2fblog%2findex%3fentryID=4558550&name=arangure_jorge_jr&addata=2009_insdr_mod_mlb_xxx_xxx",
      "http://latimesblogs.latimes.com/sports_blog/2009/08/angels-guerrero-slams-400th-career-home-run-.html",
      "http://minors.baseball-reference.com/players.cgi?pid=5922",
      "http://mlb.mlb.com/team/player.jsp?player_id=115223",
      "http://sports.espn.go.com/mlb/columns/story?columnist=stark_jayson&page=rumblings/080424",
      "http://sports.espn.go.com/mlb/news/story?id=1706614",
      "http://sports.espn.go.com/mlb/players/stats?playerId=3576",
      "http://sports.espn.go.com/mlb/recap?gameId=301022113"
    ], arr)
  end

  def test_find_link_info_none
    linkinfo = @detective.find_link_info([
      3,
      'GTV',
      'M',
      '403719123',
      '403677528',
      'Paul Benjamin Austin',
      '-24',
      Time.parse('2010-02-10T22:17:39Z'),
      "/* Former News Presenters */"
    ])
    assert_equal([], linkinfo)
    
    linkinfo = @detective.find_link_info([
      5,
      'User talk:Yourinface',
      'N',
      '403737191',
      '415546201',
      'Ohnoitsjamie',
      '507',
      Time.parse('2010-02-10T22:17:39Z'),
      "test 2"
    ])
    assert_equal([], linkinfo)
    linkinfo = @detective.find_link_info(@info)
    assert_equal([], linkinfo)
  end

  def test_investigate
    @clazz.setup_table(@db)
    res = @detective.investigate(@info2)
    assert_equal(true, res)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @clazz.setup_table(@db)
    end
  end

  def test_find_source
    source = @detective.find_source('http://example.com/')
    known_source = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\r\n<HTML>\r\n<HEAD>\r\n  <META http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\r\n  <TITLE>Example Web Page</TITLE>\r\n</HEAD> \r\n<body>  \r\n<p>You have reached this web page by typing &quot;example.com&quot;,\r\n&quot;example.net&quot;,&quot;example.org&quot\r\n  or &quot;example.edu&quot; into your web browser.</p>\r\n<p>These domain names are reserved for use in documentation and are not available \r\n  for registration. See <a href=\"http://www.rfc-editor.org/rfc/rfc2606.txt\">RFC \r\n  2606</a>, Section 3.</p>\r\n</BODY>\r\n</HTML>\r\n\r\n"
    assert_equal([known_source, true], source)
    
    source = @detective.find_source('http://example.com')
    known_source = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\r\n<HTML>\r\n<HEAD>\r\n  <META http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\r\n  <TITLE>Example Web Page</TITLE>\r\n</HEAD> \r\n<body>  \r\n<p>You have reached this web page by typing &quot;example.com&quot;,\r\n&quot;example.net&quot;,&quot;example.org&quot\r\n  or &quot;example.edu&quot; into your web browser.</p>\r\n<p>These domain names are reserved for use in documentation and are not available \r\n  for registration. See <a href=\"http://www.rfc-editor.org/rfc/rfc2606.txt\">RFC \r\n  2606</a>, Section 3.</p>\r\n</BODY>\r\n</HTML>\r\n\r\n"
    assert_equal([known_source, true], source)
    
    source = @detective.find_source('http://example.com/asdfasdf')
    assert_equal(['Net::HTTPNotFound', false], source)
    
    source = @detective.find_source('http://pqualsdkjfladf.com/asdfasdf') #non-existent url
    assert_equal(['SocketError', false], source)
  end

end