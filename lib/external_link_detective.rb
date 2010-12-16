require 'detective.rb'
require 'mediawiki_api.rb'
require 'open-uri'

class ExternalLinkDetective < Detective
  def table_name
    'link'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      revision_id integer,                              --foreign key to reference the original revision
      link string,
      source text,
      FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)   --TODO this table name probably shouldn't be hard coded
      --FOREIGN KEY(user) REFERENCES irc_wikimedia_org_en_wikipedia(user) --TODO
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
    	db_write!(['revision_id', 'link', 'source'],
	[info[0], linkentry["link"], linkentry["source"]])
    end	
  end	
  
  def find_link_info info

    #http://en.wikipedia.org/w/api.php?action=query&prop=extlinks&revids=800129
    xml= get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[3]})
    res = parse_xml(xml)
    links_new = res.first['pages'].first['page'].first['extlinks']
    if(links_new!=nil)
	links_new = links_new.first['el']
    else
	links_new = []
    end

    xml= get_xml({:format => :xml, :action => :query, :prop => :extlinks, :revids => info[4]})
    res = parse_xml(xml)
    links_old = res.first['pages'].first['page'].first['extlinks']

    if(links_old!=nil)
	links_old = links_old.first['el']
    else
	links_old = []
    end

    linkdiff = links_new - links_old
    
    linkarray = Array.new(linkdiff.length, Hash.new)
    i=0
    linkdiff.each do |link|
       source = open(link['content']){|f|f.read}
       linkarray[i]={"link" => link['content'], "source" => source}
       i = i+1
    end
    linkarray
  end
  
end