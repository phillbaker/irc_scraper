require 'detective.rb'
require 'mediawiki_api.rb'

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
      --page_placement integer,
           --byte number where revision starts
      page_last_revision_id integer,
      page_last_revison_time timestamp(20),
           --time of last revision on this page
      --popularity
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
      ['sample_id', 'page_last_revison_id', 'page_last_revision_time'],
      [info[0]] + page
    )
  end

  def find_page_history info
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :titles => info[1], :rvlimit => '2', :rvprop => 'ids|timestamp' })
    res = parse_xml(xml)
    [res.first['pages'].first['page'].first['revisions'].last['rev'].first['ids'], res.first['pages'].first['page'].first['revisions'].last['rev'].first['timestamp']]
  end
  
end