require 'detective.rb'
require 'mediawiki_api.rb'
require 'uri'
require 'net/http'

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
    
    rownum = 0
    linkarray.each do |linkentry|
      rownum = db_write!(
        ['revision_id', 'link', 'source'],
	      [info[0], linkentry["link"], linkentry["source"]]
	    )
    end	
    rownum
  end	
  
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
    xml = get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[3]})
    res = parse_xml(xml)
    links_new = res.first['pages'].first['page'].first['extlinks']
    if(links_new != nil)
	    links_new = links_new.first['el']
    else
	    links_new = []
    end
    links_new.collect! do |link|
      link['content']
    end

    xml= get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[4]})
    res = parse_xml(xml)
    #can have bad revid's (ie first edits on a page)
    links_old = []
    if(res.first['badrevids'] == nil)
      links_old = res.first['pages'].first['page'].first['extlinks']

      if(links_old != nil)
  	    links_old = links_old.first['el']
      else
  	    links_old = []
      end
      links_old.collect! do |link|
        link['content']
      end
    end
    

    linkdiff = links_new - links_old
    
    linkarray = []
    linkdiff.each do |link|
      #puts 'found a link!'
      source,success = find_source(link)
      linkarray << {"link" => link, "source" => source, "http_response" => success}
    end
    linkarray
  end
  
  def find_source(url)
    #TODO do a check for the size and type-content of it before we pull it
    #binary files we probably don't need to grab and things larger than a certain size we don't want to grab
    uri = URI.parse(url)
    
    http = Net::HTTP.new(uri.host)
    resp = nil
    begin
      path = uri.path.to_s.empty? ? '/' : uri.path
      resp = http.request_get(path, 'User-Agent' => 'WikipediaAntiSpamBot/0.1 (+hincapie.cis.upenn.edu)')
    rescue SocketError => e
      resp = e
    end
    
    ret = []
    if((resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound))
      if resp.content_type == 'text/html'
        ret << resp.body[0..10**5] #truncate at 100kb; not a good way to deal with size, should check the headers only
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
