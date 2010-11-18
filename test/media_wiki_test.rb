require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'mediawiki_api.rb'

class MediaWikiApiTest < Test::Unit::TestCase
  
  def test__form_url
    assert_equal(
      WIKI_API_URL+'?action=paraminfo&format=xml&',          #http://en.wikipedia.org/w/api.php?format=xml&action=paraminfo
                                                            #this isn't so hot as the order we pass paramters in isn't guaranteed - a hash has no order
      _form_url({:format => :xml, :action => :paraminfo})
    )
  end
  
end
