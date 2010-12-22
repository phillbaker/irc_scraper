require 'detective.rb'
require 'mediawiki_api.rb'
require 'time'
require 'sqlite3'

class PageDetective < Detective
  def table_name
    'page'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      sample_id integer,                                                      --foreign key to reference the original revision
      page_last_revision_id integer,
      page_last_revision_time timestamp(20),               --time of last revision on this page
      --popularity
      page_text text,
      --protection string,
      length integer,
      num_views integer,
      created DATE DEFAULT (datetime('now','localtime')),
      FOREIGN KEY(sample_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)   --TODO this table name probably shouldn't be hard coded
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
    page = find_page_history(info)
    db_write!(
      ['sample_id', 'page_last_revision_id', 'page_last_revision_time', 'page_text', 'num_views', 'length'],
      [info[0]] + page
    )
  end

  def find_page_history info
    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=342098230&rvprop=timestamp|user|comment|content
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => info[4], :rvprop => 'ids|timestamp|user|comment|content'})
    res = parse_xml(xml)
    rev_id = nil
    time = nil
    if(res.first['badrevids'] == nil)
      rev_id = res.first['pages'].first['page'].first['revisions'].last['rev'].first['revid']
      time = Time.parse(res.first['pages'].first['page'].first['revisions'].last['rev'].first['timestamp']).to_i
    end
    
    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=230948209&rvprop=content
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => info[3], :rvprop => 'content'})
    res2 = parse_xml(xml)
    source = res2.first['pages'].first['page'].first['revisions'].first['rev'].first['content'].to_s
  
    #http://en.wikipedia.org/w/api.php?action=query&titles=Albert%20Einstein&prop=info&inprop=protection|talkid
    xml = get_xml({:format => :xml, :action => :query, :revids => info[4], :prop => :info, :inprop => 'protection|talkid'})
    res3 = parse_xml(xml)
    num_views = nil
    length = nil
    if(res.first['badrevids'] == nil)
      num_views = res3.first['pages'].first['page'].first['counter'].to_i
      length = res3.first['pages'].first['page'].first['length'].to_i
    end
    
    #Need to encode this into a string using sqlite method or serialize it somehow
    #puts encode(res3.first['pages'].first['page'].first['protection'])
    
    [rev_id, time.to_s, source, num_views.to_s, length.to_s]
  end  
end