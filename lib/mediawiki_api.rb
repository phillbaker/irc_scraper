require 'uri'
require 'net/http'
require 'rubygems'
require 'xmlsimple'

#TODO log calls to the API to look at how effective(or not) we are
#TODO put in module
#TODO should be done like https://github.com/pauldix/typhoeus/blob/master/examples/twitter.rb ?
# So once we manage our threads, we can make this faster, either https://github.com/pauldix/typhoeus or http://curb.rubyforge.org/ or http://curl-multi.rubyforge.org/
# typhoeus uses libcurl and libcurl multi, with custom bindings...the question is: how do we add to its queue from multiple threads?
# so EventMachine does have an internal thread pool using EM.defer...
# also considered: https://github.com/danielbush/ThreadPool; https://github.com/fizx/thread_pool; https://github.com/movitto/simrpc/blob/master/lib/simrpc/thread_pool.rb

# Use https://github.com/hasmanydevelopers/RDaneel (obey Robot.txt) on top of https://github.com/igrigorik/em-http-request ?
# This function returns xml from Wikipedia's English installation API. 
# 
# params should be a hash.
def get_xml(params = {:format => :xml, :action => :query})#TODO put these in so that they're default and not lost when we pass stuff in...
  url = _form_url(params)
  
  #TODO wonder if I should make a generic library for external url requests, to standardize the header/etc?
  #requests without user-agents are refused. See:
  #http://www.mooduino.co.uk/2010/04/wikipedia-api-user-agent-string-in-php.html
  retries = 2
  begin
    http = Net::HTTP.new(WIKI_API_SERVER) #en.wikipedia.org
    resp = http.request_get(WIKI_API_PATH + url, 'User-Agent' => 'WikipediaAntiSpamBot/0.1 (+hincapie.cis.upenn.edu)')
  
    raise "POST FAILED:" + resp.inspect unless resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound
    #retry if resp.body.to_s.empty?
    resp.body
  rescue Net::HTTPBadResponse, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::ECONNREFUSED, SocketError, 
           Timeout::Error, Errno::EINVAL, EOFError, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    if retries > 0
      retries -= 1
      retry
    else
      raise Exception.new("Connection timed out after more than 3 retries: #{e}")
   end
  end
end   

#helper function to form the parameters of the get request
def _form_url(params)
  #implode params to concat 
  url = '?'
  params.each do |key, value|
    #val = URI.escape(unsafe_variable, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    safe_key = URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    safe_value = URI.escape(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    url += safe_key + '=' + safe_value + '&'
  end
  url
end

# This function parses the xml response from Wikipedia. If given the XMl, it will return a native ruby list of the structure.
def parse_xml(xml)
  hash = XmlSimple.xml_in(xml)
  hash['query']#return just the results of the query
end

#TODO move to using https://github.com/jnunemaker/crack instead of xmlsimple
#def get_info params
#parse_xml(get_xml(params))
#end
