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
      revision_id integer,                              
      http_response text,
      link text,
      source text,
      description text,
      created DATE DEFAULT (datetime('now','localtime'))
SQL
    end
  end

  #info is a list: 
  # see notes before start_detective in enwiki_bot
  def investigate info
    linkarray = info.last
    
    results = []
    linkarray.each do |arr|
      #puts arr.first
      source, success = find_source(arr.first)
      #puts find_source(arr.first)[0..100]
      ret << {:link => arr.first, :source => source, :http_response => success, :description => arr.last}
    end
    
    results.each do |linkentry|
      db_write!(
        ['revision_id', 'link', 'source', 'response', 'description'],
	      [info[2], linkentry[:link], linkentry[:source], linkentry[:http_response], linkentry[:description]]
	    )
    end	
    true
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
    else #TODO follow redirects!
      ret << resp.class.to_s
      ret << false
    end
    ret
  end
  
end
