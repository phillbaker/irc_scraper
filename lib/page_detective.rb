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
      revision_id integer,                                                      --foreign key to reference the original revision
      FOREIGN KEY(revision_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)   --TODO this table name probably shouldn't be hard coded
SQL
    end
  end

  #info is a list: 
  # 0: primary_id (string), 
  # 1: article_name (string), 
  # 2: desc (string), 
  # 3: url (string), 
  # 4: user (string), 
  # 5: byte_diff (int), 
  # 6: timestamp (Time object), 
  # 7: description (string)
  def investigate info
    #TODO raise NotImplementedError
  end
  
end