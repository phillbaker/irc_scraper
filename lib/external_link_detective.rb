require 'detective.rb'
require 'mediawiki_api.rb'
require 'uri'
require 'cgi'
require 'net/http'
require 'bundler/setup'
require 'nokogiri'

class ExternalLinkDetective < Detective
  def self.table_name
    'link'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def self.columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      revision_id integer,                              --foreign key to reference the original revision
      http_response boolean,
      link string,
      source text,
      description text,
      created DATE DEFAULT (datetime('now','localtime')),
      FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)   --TODO this table name probably shouldn't be hard coded
SQL
    end
  end

  #info is a list: 
  # 0: sample_id (string), 
  # 1: article_name (string), 
  # 2: desc (string), 
  # 3: rev_id (string),
  # 4: old_id (string)
  # 5: user (string), 
  # 6: byte_diff (int), 
  # 7: timestamp (Time object), 
  # 8: description (string)
  def investigate info
        
    linkarray = find_link_info(info)
    
    linkarray.each do |linkentry|
      db_write!(
        ['revision_id', 'link', 'source', 'description'],
	      [info[0], linkentry["link"], linkentry["source"], linkentry["description"]]
	    )
    end	
    true
  end	
  
  #really only uses revid and previous
  def find_link_info info
    #this is actually 'page' stuff
    #take popularity from: http://www.trendingtopics.org/page/[article_name]; links to csv's with daily and hourly popularity
    #http://stats.grok.se/en/top <- lists top pages
    #http://stats.grok.se/en/[year][month]/[article_name]
    #also http://toolserver.org/~emw/wikistats/?p1=Barack_Obama&project1=en&from=12/10/2007&to=12/11/2010&plot=1
    #http://wikitech.wikimedia.org/view/Main_Page
    #http://lists.wikimedia.org/pipermail/wikitech-l/2007-December/035435.html
    #http://wiki.wikked.net/wiki/Wikimedia_statistics/Daily
    #http://aws.amazon.com/datasets/Encyclopedic/4182
    #https://github.com/datawrangling/trendingtopics

    #link popularity/safety stuff:
    #http://code.google.com/apis/safebrowsing/
    #http://groups.google.com/group/google-safe-browsing-api/browse_thread/thread/b711ba69a4ecbb2f/29aa959a3a28a0bd?#29aa959a3a28a0bd

    #this is what we're going to do: get all external links for prev_id and all external links for curr_id and diff them, any added => new extrnal links to find
    #http://en.wikipedia.org/w/api.php?action=query&prop=extlinks&revids=800129
    #http://en.wikipedia.org/w/api.php?action=query&prop=extlinks&revids=409897423&ellimit=500
    #http://en.wikipedia.org/w/api.php?action=query&prop=extlinks&revids=409897009&ellimit=500
    #diff text: http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=409897423&rvdiffto=prev
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => info[3], :rvdiffto => 'prev'})
    diff_text = Nokogiri.XML(xml).css('diff').children.to_s
    diff_html = CGI.unescapeHTML(diff_text)
    noked = Nokogiri.HTML(diff_html)
    
    #TODO can have bad revid's (ie first edits on a page)
    linkarray = []
    noked.css('.diff-addedline').each do |td| #TODO should probably be looking specifically at .diffchange children for added text within the line
      revision_line = Nokogiri.HTML(CGI.unescapeHTML(td.children.to_s)).css('div').children
      #http://daringfireball.net/2010/07/improved_regex_for_matching_urls
      #%r{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}
      url = %r{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}
      #based on http://www.mediawiki.org/wiki/Markup_spec/BNF/Links
      external_link_regex = /\[(#{url}\s*(.*?))\]/
      #TODO pull any correctly formed links too?
      res = revision_line.to_s.scan(external_link_regex) #TODO test this on pages with multiple links...
      if res.size > 0
        #p res
        res = res.first.compact
        #["http://www.eyemagazine.com/feature.php?id=62&amp;fid=270 Designing heroes", "http://www.eyemagazine.com/feature.php?id=62&amp;fid=270", "Designing heroes"]
        linkarray << [res[1], #link
                      res[2]] #description
      end
    end
    
    ret = []
    linkarray.each do |arr|
      #puts arr.first
      source, success = find_source(arr.first)
      #puts find_source(arr.first)[0..100]
      ret << {"link" => arr.first, "source" => source, "http_response" => success, 'description' => arr.last}
    end
    ret
  end
  
  def find_source(url)
    #TODO do a check for the size and type-content of it before we pull it
    #binary files we probably don't need to grab and things larger than a certain size we don't want to grab
    uri = URI.parse(url)
    
    http = Net::HTTP.new(uri.host)
    resp = nil
    begin
      path = uri.path.to_s.empty? ? '/' : "#{uri.path}?#{uri.query}"
      resp = http.request_get(path, 'User-Agent' => 'WikipediaAntiSpamBot/0.1 (+hincapie.cis.upenn.edu)')
    rescue SocketError => e
      resp = e
    end
    
    ret = []
    if(resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound)
      if resp.content_type == 'text/html'
        #puts resp.body.length
        ret << resp.body[0..10**5] #truncate at 100K characters; not a good way to deal with size, should check the headers only
      else
        ret << resp.content_type
      end
      ret << true
    else
      ret << resp.class.to_s
      ret << false
    end
    ret
    # response = Net::HTTP.get_response(URI.parse(uri_str))
    # case response
    # when Net::HTTPSuccess     then response
    # when Net::HTTPRedirection then fetch(response['location'], limit - 1)
    # else
    #   response.error!
    # end
    
    #response = nil
    #Net::HTTP.start('some.www.server', 80) {|http|
    #  response = http.head('/index.html')
    #}
    #p response['content-type']
  end
  
end
