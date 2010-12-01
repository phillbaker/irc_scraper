require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'mediawiki_api.rb'

class MediaWikiApiTest < Test::Unit::TestCase
  
  def test__form_url
    assert_equal(
      '?format=xml&action=paraminfo&',          #http://en.wikipedia.org/w/api.php?format=xml&action=paraminfo
                                                            #this isn't so hot as the order we pass paramters in isn't guaranteed - a hash has no order
      _form_url({:format => :xml, :action => :paraminfo})
    )
  end
  
  def test__form_url2
    assert_equal(
      '?format=xml&letitle=User:Tisane&list=logevents&action=query&letype=newusers&',
      _form_url({:format => :xml, :action => :query, :list => :logevents, :letitle => 'User:Tisane', :letype => :newusers })
    )
  end
  
  def test_get_xml
    #http://en.wikipedia.org/w/api.php?format=xml&action=query&prop=info&revids=234354694
    #TODO this shouldn't need to hit the actual API
    assert_equal(
      '<?xml version="1.0"?><api><query><pages><page pageid="8186006" ns="10" title="Template:Chinese calendar/month/63/9" touched="2010-11-14T09:36:20Z" lastrevid="392469940" counter="0" length="1005" /></pages></query></api>',
      get_xml({:format => :xml, :action => :query, :prop => :info, :revids => 234354694 })
    )
  end
  
  def test_parse_xml
    assert_equal(
      [{"pages"=>
         [{"page"=>
            [{"lastrevid"=>"392469940",
              "touched"=>"2010-11-14T09:36:20Z",
              "title"=>"Template:Chinese calendar/month/63/9",
              "ns"=>"10",
              "length"=>"1005",
              "counter"=>"0",
              "pageid"=>"8186006"
            }]
         }]
      }],
      parse_xml('<?xml version="1.0"?><api><query><pages><page pageid="8186006" ns="10" title="Template:Chinese calendar/month/63/9" touched="2010-11-14T09:36:20Z" lastrevid="392469940" counter="0" length="1005" /></pages></query></api>')
    )
  end
  
end
