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
      source_content_error = find_source(arr.first)
      results << {:link => arr.first, :source => source_content_error, :description => arr.last}
    end

    results.each do |linkentry|
      db_queue(
        ['revision_id', 'link', 'source', 'description'],
	      [info[2], linkentry[:link], linkentry[:source], linkentry[:description]]
	    )
    end	
    true # :)
  end	
  
  #return either the source, a non text/html contenttype or the httperror class, all as strings
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
    
    ret = ''
    if(resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound)
      #truncate at 100K characters; not a good way to deal with size, should check the headers only
      #else set the body to the content type
      ret = (resp.content_type == 'text/html') ? resp.body[0..10**5] : resp.content_type
    else #TODO follow redirects!
      #if it's a bad http response set the body equal to that response
      ret = resp.class.to_s
    end
    ret
  end
  
end
