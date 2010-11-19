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
  
  #requests without user-agents are refused. See:
  #http://www.mooduino.co.uk/2010/04/wikipedia-api-user-agent-string-in-php.html
  #"User-Agent"
  #WikipediaSpamBot/0.1 (+hincapie.cis.upenn.edu)

  #resp = Net::HTTP.get_response(URI.parse(url))

  url = URI.parse("http://www.whatismyip.com/automation/n09230945.asp")

  req = Net::HTTP::Get.new(url.path)
  req.add_field('User-Agent', 'WikipediaSpamBot/0.1 (+hincapie.cis.upenn.edu)')

  resp = Net::HTTP.new(url.host).start do |http|
    http.request(req)
  end

  raise "POST FAILED:" + resp.inspect unless resp.is_a? Net::HTTPOK or resp.is_a? Net::HTTPFound
  resp.body #get xml
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
