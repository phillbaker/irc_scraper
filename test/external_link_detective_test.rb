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
    @clazz.setup_table(@db)
  end
  
  def test_investigate
    #old info:
    # [2,
    #   'Vladimir Guerrero',
    #   'M',
    #   '392473934',
    #   '392337290',
    #   'Briskbaby',
    #   '+290',
    #   "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    # ]
    res = @detective.investigate([
      "Islam in the Democratic Republic of the Congo", 
      "", 410276420, 395536324, "Anna Frodesiak", 12, 
      "link ivory trade", 
      "&lt;tr&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n  &lt;td colspan=\"2\" class=\"diff-lineno\"&gt;Line 1:&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;{{islam by country}}&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt;-&lt;/td&gt;\n  &lt;td class=\"diff-deletedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt;+&lt;/td&gt;\n  &lt;td class=\"diff-addedline\"&gt;&lt;div&gt;\n'''[[Islam]] in the [[Democratic Republic of the Congo]]''' is not a recent phenomenon, as it has been present within the area since the 18th century, when [[Arab]] traders from [[East Africa]] pushed into the interior for [[&lt;span class=\"diffchange\"&gt;ivory trade|&lt;/span&gt;ivory]] and [[slave]] trading purposes. Today, Muslims constitute approximately 10.4% of the Congolese population.&amp;lt;ref&amp;gt;[https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html CIA - The World Factbook - Congo, Democratic Republic of the&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;&amp;lt;ref&amp;gt;[http://www.state.gov/r/pa/ei/bgn/2823.htm Congo (Kinshasa) (01/08)&amp;lt;!-- Bot generated title --&amp;gt;]&amp;lt;/ref&amp;gt;\n  &lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;/td&gt;\n&lt;/tr&gt;\n&lt;tr&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n  &lt;td class=\"diff-marker\"&gt; &lt;/td&gt;\n  &lt;td class=\"diff-context\"&gt;&lt;div&gt;==Notes==&lt;/div&gt;&lt;/td&gt;\n&lt;/tr&gt;\n", 
      {"user"=>"Anna Frodesiak", "timestamp"=>"2011-01-27T00:47:31Z", "revid"=>"410276420", "size"=>"885", "title"=>"Islam in the Democratic Republic of the Congo", "from"=>"395536324", "parsedcomment"=>"link ivory trade", "to"=>"410276420", "parentid"=>"395536324", "ns"=>"0", "space"=>"preserve", "comment"=>"link ivory trade", "pageid"=>"6110090"}, 
      [], 
      [
        ["https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html", "CIA - The World Factbook - Congo, Democratic Republic of the<!-- Bot generated title -->"]
      ]
    ])
    
    assert_equal([["INSERT INTO link ( revision_id, link, source, description, headers ) VALUES ( 410276420, 'https://www.cia.gov/library/publications/the-world-factbook/geos/cg.html', 'Net::HTTPMovedPermanently', 'CIA - The World Factbook - Congo, Democratic Republic of the<!-- Bot generated title -->', '\004\b{\006:\rlocation[\006\"3https://www.cia.gov/redirects/ciaredirect.html' ) "]], @queue)
  end
  
  def test_setup_table
    #to test the sql of the table definition
    assert_nothing_raised do
      @clazz.setup_table(@db)
    end
  end
  
  def test_find_source
    source = @detective.find_source('http://example.com/')
    known_source = ["<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\r\n<HTML>\r\n<HEAD>\r\n  <META http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\r\n  <TITLE>Example Web Page</TITLE>\r\n</HEAD> \r\n<body>  \r\n<p>You have reached this web page by typing &quot;example.com&quot;,\r\n&quot;example.net&quot;,&quot;example.org&quot\r\n  or &quot;example.edu&quot; into your web browser.</p>\r\n<p>These domain names are reserved for use in documentation and are not available \r\n  for registration. See <a href=\"http://www.rfc-editor.org/rfc/rfc2606.txt\">RFC \r\n  2606</a>, Section 3.</p>\r\n</BODY>\r\n</HTML>\r\n\r\n",
     {:date=>["Thu, 27 Jan 2011 18:17:22 GMT"],
      :connection=>["close"],
      :"accept-ranges"=>["bytes"],
      :"content-type"=>["text/html; charset=UTF-8"],
      :etag=>["\"573c1-254-48c9c87349680\""],
      :"content-length"=>["596"],
      :age=>["769"],
      :server=>["Apache"],
      :"last-modified"=>["Fri, 30 Jul 2010 15:30:18 GMT"]}]
    assert_equal(known_source.first, source.first) #test source
    
    source = @detective.find_source('http://example.com/asdfasdf')
    assert_equal('Net::HTTPNotFound', source.first) #test source
    
    source = @detective.find_source('http://pqualsdkjfladf.com/asdfasdf') #non-existent url
    assert_equal('SocketError', source.first)
  end
  
  def test_okay_with_gzip
    source = @detective.find_source('http://www.colocolo.cl/2009/07/plantel/')
    assert_equal(source.last[:'content-encoding'].first, 'gzip')
    
    assert_nothing_raised do
      res = @detective.investigate([[nil, nil, 410312383], [nil] * 7, [['http://www.colocolo.cl/2009/07/plantel/', '']]])
    end
  end
  
  def test_binary_file
    #http://tennisbc.org/files/pospisil.pdf
    assert_nothing_raised do
      res = @detective.investigate([[nil] * 10, [['http://tennisbc.org/files/pospisil.pdf', '']]])
    end
  end
  
  def test_uncaught_errors
    #410371611
    #410394508
    # http://en.wikipedia.org/wiki/Herbert_McCabe|Herbert
    assert_nothing_raised do
      #with a wikipedia url
      @detective.investigate([[nil, nil, 410410115], [nil] * 7, [['http://en.wikipedia.org/wiki/Herbert_McCabe|Herbert', '']]])
    end
    assert_nothing_raised do
      #with a down url; this takes forever...
    #  @detective.investigate([[nil, nil, 410395683], [nil] * 7, [['http://www.bomis.com/about/bomis_faq.html', '']]])
    end
    #410430950 www.spanishdict.com
    assert_nothing_raised do
      #with out http
      @detective.investigate([[nil, nil, 410430950], [nil] * 7, [['www.spanishdict.com', '']]])
    end
    
    # assert_nothing_raised do #one of the follow takes forever to timeout
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.ellisislandimmigrants.org/ellis_island_archives.htm', '']]])
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://82.165.253.62/quarterly/spr06/kissing.pdf', '']]])
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://sumagazine.syr.edu/summer03/alumnijournal/index.html', '']]])
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.answers.com/topic/ring-of-the-fisherman', '']]])
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.religionfacts.com/christianity/things/icons.htm', '']]])
    #       @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.history.com/minisite.do?content_type=Minisite_Generic&amp;content_type_id=50231&amp;display_order=2&amp;sub_display_order=8&amp;mini_id=1459', '']]])
    #       #@detective.investigate([[nil, nil, 410444868], [nil] * 7, [['', '']]])
    #     end
    #410445179 
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://books.google.com/books?id=ZA4EAAAAMBAJ&amp;pg=PA24&amp;lpg=PA24&amp;dq=Diva:+The+Singles+Collection+sarah+brightman++Nielsen+SoundScan&amp;source=bl&amp;ots=0IC5s6ktyq&amp;sig=0blfM6hOIZcIBQQq96_INMcPDqU&amp;hl=es&amp;ei=mrUmTer0GIep8Ab1_cWrAQ&amp;sa=X&amp;oi=book_result&amp;ct=result&amp;resnum=8&amp;ved=0CFYQ6AEwBw#v=onepage&amp;q=Diva%3A%20The%20Singles%20Collection%20sarah%20brightman%20%20Nielsen%20SoundScan&amp;f=false', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.billboard.biz/bbbiz/content_display/industry/news/e3i4cdea7d2a4bcd3986f84169caf3af94d', '']]])
    end
    
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.ellisislandimmigrants.org/ellis_island_archives.htm', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://sumagazine.syr.edu/summer03/alumnijournal/index.html', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.answers.com/topic/ring-of-the-fisherman', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.religionfacts.com/christianity/things/icons.htm', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://www.history.com/minisite.do?content_type=Minisite_Generic&amp;content_type_id=50231&amp;display_order=2&amp;sub_display_order=8&amp;mini_id=1459', '']]])
      @detective.investigate([[nil, nil, 410444868], [nil] * 7, [['http://82.165.253.62/quarterly/spr06/kissing.pdf', '']]])
    end
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410445320], [nil] * 7, [['http://thepianoparlour.squarespace.com/whats-opera-doc/', '']]])
    end
    # 
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410449382], [nil] * 7, [['http://www.sikh-heritage.co.uk/arts/bollywoodgreats/bollygreats.htm', '']]])
    end
    
    #http://dsal.uchicago.edu/books/annualofurdustudies/pager.html?volume=5&amp;objectid=PK2151.A6152_5_087.gif
    #http://www.dawn.com/weekly/images/archive/050814/images1.htm
    #http://www.imdb.com/title/tt0325447/
    #http://www.sahitya-akademi.gov.in/old_version/awa10322.htm#urdu
    #410449952 http://www.ku.edu.af/index.php?module=cms&amp;action=showfulltext&amp;id=gen9Srv40Nme31_6314_1220327784&amp;sectionid=init_1
  end
  
  def test_uncaught_errors2
    #AAI RQ-7 Shadow () 
    assert_nothing_raised do
      #Net::HTTPBadResponse
      @detective.investigate([[nil, nil, 410453846], [nil] * 7, [['http://www.scribd.com/doc/27362068/Flight-International-12-18-Jan-2010', '']]])
    end
    # Herb Chambers () 
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410454023], [nil] * 7, [['http://www.herbcares.com/', '']]])
    end
    # PlayStation Portable successor () 
    assert_nothing_raised do
      @detective.investigate([[nil, nil, 410459147], [nil] * 7, [['http://g4tv.com/thefeed/blog/tag/10441/PlayStation-NGP.html', '']]])
    end
  end
  
  # def test_find_link_info
  #     hash = @detective.find_link_info([nil, nil, nil, 409897423, 409897009]).first
  #     assert_equal('Designing heroes', hash['description'])
  #     assert_equal(true, hash['http_response'])
  #     assert_equal('http://www.eyemagazine.com/feature.php?id=62&amp;fid=270', hash['link'])
  #     assert_operator 10000, :<=, hash['source'].length #just make sure we're getting a bunch of data
  #   end
  # 
  #   def test_find_link_info_none
  #     linkinfo = @detective.find_link_info([
  #       3,
  #       'GTV',
  #       'M',
  #       '403719123',
  #       '403677528',
  #       'Paul Benjamin Austin',
  #       '-24',
  #       Time.parse('2010-02-10T22:17:39Z'),
  #       "/* Former News Presenters */"
  #     ])
  #     assert_equal([], linkinfo)
  #     
  #     linkinfo = @detective.find_link_info([
  #       5,
  #       'User talk:Yourinface',
  #       'N',
  #       '403737191',
  #       '415546201',
  #       'Ohnoitsjamie',
  #       '507',
  #       Time.parse('2010-02-10T22:17:39Z'),
  #       "test 2"
  #     ])
  #     assert_equal([], linkinfo)
  #     linkinfo = @detective.find_link_info([1,
  #   'Amar Ben Belgacem',
  #   'M',
  #   '392473902',
  #   '391225974',
  #   'SD5',
  #   '+226',
  #   Time.parse('2010-02-10T22:17:39Z'),
  #   "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
  # ])
  #     assert_equal([], linkinfo)
  #   end
  #
end