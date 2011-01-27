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
    hash = @detective.find_link_info([nil, nil, nil, 409897423, 409897009]).first
    assert_equal('Designing heroes', hash['description'])
    assert_equal(true, hash['http_response'])
    assert_equal('http://www.eyemagazine.com/feature.php?id=62&amp;fid=270', hash['link'])
    assert_operator 10000, :<=, hash['source'].length #just make sure we're getting a bunch of data
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

  def test_finds_wikilinks_in_diff_changes
    #rev_id = 362663028
    diff_html = <<-END
    <tr>
      <td colspan="2" class="diff-lineno">Line 44:</td>
      <td colspan="2" class="diff-lineno">Line 44:</td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>===Early anthropocene===</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>===Early anthropocene===</div></td>
    </tr>
    <tr>
      <td class="diff-marker">-</td>
      <td class="diff-deletedline"><div>
    Arguing the early Anthropocene hypothesis, [[William Ruddiman]] claims that the Anthropocene, as defined by significant human impact on greenhouse gas emissions, began not in the industrial era, but 8,000 years ago, as ancient farmers cleared forests to grow crops.&lt;ref&gt;{{cite journal |last=Mason |first=Betsy |authorlink= |coauthors= |year=2003 |month= |title=Man has been changing climate for 8,000 years |journal=[[Nature (journal)|Nature]] |volume= |issue= |pages= |doi=10.1038/news031208-7 |url= |accessdate= |quote= }}&lt;/ref&gt;&lt;ref&gt;{{cite web |url= http://www.newscientist.com/news/news.jspid=ns99994464 |title= Early farmers warmed Earth's climate |work= New Scientist |author= Adler, Robert |date= 2003-12-11 |accessdate= 2008-02-04 }}&lt;/ref&gt;&lt;ref&gt;{{cite journal |title=The Anthropogenic Greenhouse Era Began Thousands of Years Ago |url=http://earth.geology.yale.edu/~avf5/teaching/Files_pdf/Ruddiman2003.pdf |author=Ruddiman, William F. |date=2003 |doi=10.1023/B:CLIM.0000004577.17928.fa |journal=Climatic Change | volume=61 |number=3 |pages=261&#x2013;293 }}&lt;/ref&gt; Ruddiman's work has in turn been challenged on the grounds that comparison with an earlier interglaciation ("Stage 11", around 400,000 years ago) suggest that 16,000 more years must elapse before the current Holocene interglaciation comes to an end, and that thus the early anthropogenic hypothesis is invalid.{{Citation needed|date=January 2010}} But Ruddiman argues that this results from an invalid alignment of recent insolation maxima with insolation minima from the past, among other irregularities which invalidate the criticism.
      </div></td>
      <td class="diff-marker">+</td>
      <td class="diff-addedline"><div>
    Arguing the early Anthropocene hypothesis, [[William Ruddiman]] claims that the Anthropocene, as defined by significant human impact on greenhouse gas emissions, began not in the industrial era, but 8,000 years ago, as ancient farmers cleared forests to grow crops.&lt;ref&gt;{{cite journal |last=Mason |first=Betsy |authorlink= |coauthors= |year=2003 |month= |title=Man has been changing climate for 8,000 years |journal=[[Nature (journal)|Nature]] |volume= |issue= |pages= |doi=10.1038/news031208-7 |url= |accessdate= |quote= }}&lt;/ref&gt;&lt;ref&gt;{{cite web |url= http://www.newscientist.com/news/news.jspid=ns99994464 |title= Early farmers warmed Earth's climate |work= New Scientist |author= Adler, Robert |date= 2003-12-11 |accessdate= 2008-02-04 }}&lt;/ref&gt;&lt;ref&gt;{{cite journal |title=The Anthropogenic Greenhouse Era Began Thousands of Years Ago |url=http://earth.geology.yale.edu/~avf5/teaching/Files_pdf/Ruddiman2003.pdf |author=Ruddiman, William F. |date=2003 |doi=10.1023/B:CLIM.0000004577.17928.fa |journal=Climatic Change | volume=61 |number=3 |pages=261&#x2013;293 }}&lt;/ref&gt; Ruddiman's work has in turn been challenged on the grounds that comparison with an earlier interglaciation ("Stage 11", around 400,000 years ago) suggest that 16,000 more years must elapse before the current Holocene interglaciation comes to an end, and that thus the early anthropogenic hypothesis is invalid.{{Citation needed|date=January 2010}} But Ruddiman argues that this results from an invalid alignment of recent insolation maxima with insolation minima from the past, among other irregularities which invalidate the criticism<span class="diffchange">. Furthermore, the argument that "something" is needed to explain the differences in the Holocene is challenged by more recent research showing that all interglacials differ [http://www.nature.com/ngeo/journal/v2/n11/abs/ngeo660.html]</span>.
      </div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>== See also ==</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>== See also ==</div></td>
    </tr>
    <!-- diff cache key enwiki:diff:version:1.11a:oldid:362628925:newid:362663028 -->
    
    END
    res = @detective.find_urls_in_diff_html(diff_html)
    assert_equal([["http://www.nature.com/ngeo/journal/v2/n11/abs/ngeo660.html", ""]], res)
  end
  
  def test_finds_interpreted_links_in_diff_changes
    #rev_id = 
    diff_html = <<-END
    END
    res = @detective.find_urls_in_diff_html(diff_html)
    assert_equal([], res)
  end
  
  def test_finds_no_interpreted_links_not_in_diff_changes
    #rev_id = 392473934, 362663028
    diff_html = <<-END<tr>
      <td colspan="2" class="diff-lineno">Line 125:</td>
      <td colspan="2" class="diff-lineno">Line 125:</td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>[[File:DSCN6884 Vladimir Guerrero.JPG|230px|thumb|Guerrero in {{Mlby|2010}} [[spring training]].]]</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>[[File:DSCN6884 Vladimir Guerrero.JPG|230px|thumb|Guerrero in {{Mlby|2010}} [[spring training]].]]</div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>On January 11, 2010, Guerrero signed a one-year, $5.5 million deal with incentives and a 2011 option with the [[Texas Rangers (baseball)|Texas Rangers]]. He broke up a no-hitter by [[Shawn Marcum]] in the seventh inning of the [[Opening Day]] game against the [[Toronto Blue Jays]] on April 5, 2010.&lt;ref&gt;[http://texas.rangers.mlb.com/news/article.jsp?ymd=20100111&amp;content_id=7898670&amp;vkey=news_tex&amp;fext=.jsp&amp;c_id=tex Guerrero joins Rangers' lineup]&lt;/ref&gt;</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>On January 11, 2010, Guerrero signed a one-year, $5.5 million deal with incentives and a 2011 option with the [[Texas Rangers (baseball)|Texas Rangers]]. He broke up a no-hitter by [[Shawn Marcum]] in the seventh inning of the [[Opening Day]] game against the [[Toronto Blue Jays]] on April 5, 2010.&lt;ref&gt;[http://texas.rangers.mlb.com/news/article.jsp?ymd=20100111&amp;content_id=7898670&amp;vkey=news_tex&amp;fext=.jsp&amp;c_id=tex Guerrero joins Rangers' lineup]&lt;/ref&gt;</div></td>
    </tr>
    <tr>
      <td class="diff-marker">-</td>
      <td class="diff-deletedline"><div>
    On May 6,2010 Guerrero hit two home runs versus the [[Kansas City Royals]] to secure a 13&#x2013;12 win. On May 13, 2010 Guerrero's walk off line drive to left field won the final game of a three game series against the Oakland Athletics in the bottom of the twelfth. On May 25, 2010 he hit two more home runs to secure another win over the [[Kansas City Royals]]. Guerrero wound up appearing in 152 games in the regular season for a Texas Rangers club that wound up winning its [[American League West|division]]. He also earned his ninth invitation to the All-Star Game.&lt;ref&gt;http://www.baseball-reference.com/players/g/guerrvl01.shtml&lt;/ref&gt;
      </div></td>
      <td class="diff-marker">+</td>
      <td class="diff-addedline"><div>
    On May 6,2010 Guerrero hit two home runs versus the [[Kansas City Royals]] to secure a 13&#x2013;12 win. On May 13, 2010 Guerrero's walk off line drive to left field won the final game of a three game series against the Oakland Athletics in the bottom of the twelfth. On May 25, 2010 he hit two more home runs to secure another win over the [[Kansas City Royals]]. Guerrero wound up appearing in 152 games in the regular season for a Texas Rangers club that wound up winning its [[American League West|division]] <span class="diffchange">and ultimately, the first pennant in Rangers' history</span>. He also earned his ninth invitation to the All-Star Game.&lt;ref&gt;http://www.baseball-reference.com/players/g/guerrvl01.shtml&lt;/ref&gt;
      </div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>==Batting style==</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>==Batting style==</div></td>
    </tr>
    <!-- diff cache key enwiki:diff:version:1.11a:oldid:392337280:newid:392473934 -->
    END
    res = @detective.find_urls_in_diff_html(diff_html)
    assert_equal([], res)
  end

  def test_finds_wikilinks_in_new_line
    #rev_id = 362663050
    diff_html = <<-END
    <tr>
      <td colspan="2" class="diff-lineno">Line 28:</td>
      <td colspan="2" class="diff-lineno">Line 28:</td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>== External links ==</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>== External links ==</div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>* {{imdb title|title=Rocky King, Inside Detective|id=0042142}}</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>* {{imdb title|title=Rocky King, Inside Detective|id=0042142}}</div></td>
    </tr>
    <tr>
      <td colspan="2">&nbsp;</td>
      <td class="diff-marker">+</td>
      <td class="diff-addedline"><div>*[http://www.dumonthistory.tv/a2.html DuMont historical website]</div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>*[http://members.aol.com/cingram/television/dumonta7.htm Article on Rocky King, Inside Detective]</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>*[http://members.aol.com/cingram/television/dumonta7.htm Article on Rocky King, Inside Detective]</div></td>
    </tr>
    <tr>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>*[http://www.oldies.com/product-view/5219D.html Oldies &#x2014; Rocky King, Inside Detective]</div></td>
      <td class="diff-marker"> </td>
      <td class="diff-context"><div>*[http://www.oldies.com/product-view/5219D.html Oldies &#x2014; Rocky King, Inside Detective]</div></td>
    </tr>
    <!-- diff cache key enwiki:diff:version:1.11a:oldid:362462606:newid:362663050 -->
    
    END
    res = @detective.find_urls_in_diff_html(diff_html)
    assert_equal([["http://www.dumonthistory.tv/a2.html", "DuMont historical website"]], res)
  end

  def test_finds_interpreted_links_in_new_line
    #rev_id = 
    diff_html = <<-END
    END
    res = @detective.find_urls_in_diff_html(diff_html)
    assert_equal([], res)
  end

  def test_finds_multiple_links
    #rev_id = 368873349
    res = @detective.find_link_info([nil, nil, nil, 362663028]).first #monster revisision with lots of links, do we get stuck in the regexes?
    assert_equal(['many'], res)
  end
  
  def test_finds_urls_not_spaced
    #rev_id = 
    res = @detective.find_link_info([nil, nil, nil, 363492332]).first
    assert_equal(['many'], res)
  end
  
  #TODO test http://en.wikipedia.org/w/index.php?title=Anthropocene&diff=next&oldid=362701983 <- edit that is partially url and partially not
end