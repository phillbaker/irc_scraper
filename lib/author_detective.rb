require 'detective.rb'
require 'mediawiki_api.rb'

require 'time'

class AuthorDetective < Detective
  def table_name
    'author'
  end

  #return a proc that defines the columns used by this detective
  #if using this as an example, you probably should copy the first two columns (the id and foreign key)
  def columns
    Proc.new do
      <<-SQL
      id integer primary key autoincrement,
      sample_id integer,                                                      --foreign key to reference the original revision
      
      --these are all true contemporaneous of the edit, post or pre-edit may be different
      account_creation timestamp(20),                                           --this should be the entry in the logevents call, but if we exceed the max number of requests, we won't get it      block_count
      account_lifetime integer,                                                 --this is the lifetime of the account in seconds
      --rights_grant_count                                                      
      --rights_removal_count
      --edits_last_second                                                       --want a figure to show recent activity do buckets instead
      --edits_last_minute
      --edits_last_hour
      --edits_last_day
      --edits_last_week
      --edits_last_month
      --edits_last_year
      --total_edits
      FOREIGN KEY(sample_id) REFERENCES irc_wikimedia_org_en_wikipedia(id)    --these foreign keys probably won't be enforced b/c sqlite doesn't include it by default--TODO this foreign table name probably shouldn't be hard coded
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
    #TODO if we already have data for a user, should we look it up?
    
    #http://en.wikipedia.org/w/api.php?action=query&titles=User:Tisane&prop=info|flagged&list=blocks|globalblocks|logevents|recentchanges|tags
    
    account = find_account_history(info)
    
    #http://en.wikipedia.org/w/api.php?action=query&list=logevents&leuser=Tisane&lelimit=max <- actions taken by user
    #get_xml({:format => :xml, :action => :query, :list => :logevents, :leuser => info[4], :lelimit => :max })
    
    #http://en.wikipedia.org/w/api.php?action=query&list=blocks&bkprop=id|user|by|timestamp|expiry|reason|range|flags&bklimit=max&bkusers=Tisane
    #get_xml({:format => :xml, :action => :query, :list => :blocks, :bkusers => info[4], :bklimit => :max, :bkprop => 'id|user|by|timestamp|expiry|reason|range|flags' })
    
    #http://en.wikipedia.org/w/api.php?action=query&list=users&ususers=Tisane&usprop=blockinfo|groups|editcount|registration|emailable
    #get_xml({:format => :xml, :action => :query, :list => :users, :ususers => info[4], :usprop => 'blockinfo|groups|editcount|registration|emailable' })
    
    #http://en.wikipedia.org/w/api.php?action=query&list=recentchanges&rcuser=Tisane&rcprop=user|comment|timestamp|title|ids|sizes|redirect|loginfo|flags
    #get_xml({:format => :xml, :action => :query, :list => :recentchanges, :rcuser => info[4], :rcprop => 'user|comment|timestamp|title|ids|sizes|redirect|loginfo|flags' })
    
    #res = parse_xml(get_xml())
    db_write!(
      ['sample_id', 'account_creation', 'account_lifetime'],
      [info[0]] + account
    )
  end
  
  def find_account_history info
    #http://en.wikipedia.org/w/api.php?action=query&list=logevents&letitle=User:Tisane&lelimit=max <- actions taken to user
    #http://en.wikipedia.org/w/api.php?action=query&list=logevents&letitle=User:Tisane&lelimit=max&letype=newusers
    #res = parse_xml(get_xml({:format => :xml, :action => :query, :list => :logevents, :letitle => 'User:' + info[4], :lelimit => :max }))
    
    #http://en.wikipedia.org/w/api.php?action=query&list=users&ususers=1.2.3.4|Catrope|Vandal01|Bob&usprop=blockinfo|groups|editcount|registration|emailable
    xml = get_xml({:format => :xml, :action => :query, :list => :users, :ususers => info[5], :usprop => 'blockinfo|groups|editcount|registration|emailable' })
    res = parse_xml(xml)
    
    create = Time.parse(res.first['users'].first['user'].first['registration'])
    life = info[7] - create
    
    #TODO get the rest of this data: 
    #<user name="Bob" editcount="4517" registration="2006-11-18T21:55:03Z" emailable="">
    #        <groups>
    #          <g>reviewer</g>
    #        </groups>
    #      </user>
    
    [create.to_i, life.to_i]
  end
end
