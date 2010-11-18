require 'uri'
require 'net/http'

#url = "http://www.whatever.com/whatever.txt"
#r = Net::HTTP.get_response(URI.parse(url).host, URI.parse(url).path)

#params should be a hash 
#
#default parameters:
#http://en.wikipedia.org/w/api.php?format=xml&action=query
#
#mediawiki parameters:
#format = xml
#:version =?
#maxlag =?
#smaxage = ignored for now
#maxage = ignored for now
#requestid = ignored for now

#GET parameters: titles,revids
def get_xml(params = {:format => :xml, :action => :query})
  url = _form_url(params)
  
  resp = Net::HTTP.get_response(URI.parse(url))
end

def _form_url(params)
  #implode params to concat 
  url = WIKI_API_URL + '?'
  params.each do |key, value|
    #val = URI.escape(unsafe_variable, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    url += key.to_s + '=' + value.to_s + '&'
  end
  url
end

def parse_xml(xml)
  
end
