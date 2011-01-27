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
      headers text,
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
      source_content_error, headers = find_source(arr.first)
      headers_str = Marshal.dump(headers)
      #ignore binary stuff for now
      encoded = headers[:'content-encoding'] ? ['gzip', 'deflate', 'compress'].include?(headers[:'content-encoding'].first) : false
      
      results << { 
        :link => arr.first, 
        :source => encoded ? 'encoded' : source_content_error, 
        :description => arr.last, 
        :headers => headers_str
      }
    end

    results.each do |linkentry|
      db_queue(
        ['revision_id', 'link', 'source', 'description', 'headers'],
	      [info[2], linkentry[:link], linkentry[:source], linkentry[:description], linkentry[:headers]]
	    )
    end	
    true # :)
  end	
  
  #return either the source, a non text/html contenttype or the httperror class, all as strings
  def find_source(url)
    #TODO do a check for the size and type-content of it _before_ we pull it
    #binary files we probably don't need to grab and things larger than a certain size we don't want to grab
    #uri = URI.parse(url)# this doesn't like wikipeida urls like http://en.wikipedia.org/wiki/Herbert_McCabe|Herbert
    url_regex = /^(.*?\/\/[^\/]*)(.*)$/x #break it up like this, we're using urls that URI doesn't parse
    parts = url.scan(url_regex)
    host = parts.first[0]
    path = parts.first[1]
    
    http = Net::HTTP.new(host)
    resp = nil
    ret = []
    begin
      resp = http.request_get(
        path.empty? ? '/' : path, 
        'User-Agent' => 'WikipediaAntiSpamBot/0.1 (+hincapie.cis.upenn.edu)'
      )
      
      if(resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound)
        #truncate at 100K characters; not a good way to deal with size, should check the headers only
        #else set the body to the content type
        if resp.content_type == 'text/html'
          ret << resp.body[0..10**5]
        else
          ret << resp.content_type
        end
      else
        ret << resp.class.to_s
      end
      #shallow convert all keys to lowercased symbols
      ret << resp.to_hash.inject({}){|memo,(k,v)| memo[k.to_s.downcase.to_sym] = v; memo} #the headers
    rescue SocketError => e
      ret << e.class.to_s
      ret << {}
    #ensure
      #if resp is a SocketError, let's raise an error
      #resp
    end
    
    # #resp is either the exception or the response
    #     ret = [] #TODO make this a hash
    #     
    #     else #TODO follow redirects!
    #       #if it's a bad http response set the body equal to that response
    #       ret << resp.class.to_s
    #       ret << {} #(resp.respond_to?(:to_hash) && !resp.is_a?(SocketError)) ? resp.to_hash : 
    #     end
    ret
  end
  
end
