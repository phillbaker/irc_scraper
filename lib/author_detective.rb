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
      account_creation timestamp(20),                                         --this should be the entry in the logevents call, but if we exceed the max number of requests, we won't get it
      account_lifetime integer,                                               --this is the lifetime of the account in seconds
      edits_last_second integer,                                              --want a figure to show recent activity do buckets instead
      edits_last_minute integer,
      edits_last_hour integer,
      edits_last_day integer,
      edits_last_week integer,
      edits_last_month integer,
      edits_last_year integer,
      total_edits integer,
      --rights string,
      --rights_grant_count                                                   
      --rights_removal_count
      groups string,                                                          --this should also cover the rights...
      num_times_blocked integer,
      block_id integer,
      blocked_by string,
      block_ts timestamp,
      block_expiry timestamp,
      block_reason text,
      user_talkpg_text text,
      created DATE DEFAULT (datetime('now','localtime')),
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
    
    #http://en.wikipedia.org/w/api.php?action=query&list=recentchanges&rcuser=Tisane&rcprop=user|comment|timestamp|title|ids|sizes|redirect|loginfo|flags
    #get_xml({:format => :xml, :action => :query, :list => :recentchanges, :rcuser => info[4], :rcprop => 'user|comment|timestamp|title|ids|sizes|redirect|loginfo|flags' })
    
    #res = parse_xml(get_xml())
   
   if(account == nil)
     
   elsif (account[11] == 0)
    db_write!(  
      [
        'sample_id', 
        'account_creation', 
        'account_lifetime', 
        'total_edits', 
        'edits_last_second', 
        'edits_last_minute', 
        'edits_last_hour', 
        'edits_last_day', 
        'edits_last_week', 
        'edits_last_month', 
        'edits_last_year', 
        'groups', 
        'num_times_blocked', 
        'user_talkpg_text'
      ],
      [info[0]] + account
    )
   else
     db_write!(
      [
        'sample_id', 
        'account_creation', 
        'account_lifetime', 
        'total_edits', 
        'edits_last_second', 
        'edits_last_minute', 
        'edits_last_hour', 
        'edits_last_day', 
        'edits_last_week', 
        'edits_last_month', 
        'edits_last_year', 
        'groups', 
        'num_times_blocked', 
        'block_id',
        'blocked_by',
        'block_ts',
        'block_expiry',
        'block_reason', 
        'user_talkpg_text'
      ],
      [info[0]] + account
    )
   end
  end
  
  def find_account_history info
    #http://en.wikipedia.org/w/api.php?action=query&list=logevents&letitle=User:Tisane&lelimit=max <- actions taken to user
    #http://en.wikipedia.org/w/api.php?action=query&list=logevents&letitle=User:Tisane&lelimit=max&letype=newusers
    #res = parse_xml(get_xml({:format => :xml, :action => :query, :list => :logevents, :letitle => 'User:' + info[4], :lelimit => :max }))
    
    #http://en.wikipedia.org/w/api.php?action=query&list=users&ususers=1.2.3.4|Catrope|Vandal01|Bob&usprop=groups|editcount|registration|emailable
    xml = get_xml({:format => :xml, :action => :query, :list => :users, :ususers => info[5], :usprop => 'groups|editcount|registration|emailable' })
    res = parse_xml(xml)
    
    rxml = res.first['users'].first['user'].first
    #if it's an IP address, won't have anything
    create = nil
    life = nil
    editcount = nil
    if(rxml['registration'] != nil)
      create = Time.parse(rxml['registration'])
      life = info[7] - create
      create = create.to_i
      life = life.to_i
    end
    
    editcount = nil
    if(rxml['editcount'] != nil)
      #for ip address users, there is no editcount, take that from below instead
      editcount = rxml['editcount']
    else
      editcount_xml = get_xml({:format => :xml, :action => :query, :list => :usercontribs, :ucuser => info[5], :uclimit => 500})
      editcount_res = parse_xml(editcount_xml)
      editcount = editcount_res.first['usercontribs'].first['item'].length
    end
    
    groups = rxml['groups']
    #emailable = res.first['users'].first['user'].first['emailable']    
    
    if(groups != nil)
	    groups = groups.first['g'].join("##")
    else
	    groups = ""
    end
    
    #http://en.wikipedia.org/w/api.php?action=query&list=usercontribs&ucuser=YurikBot
    second_ago = info[7]-1
    minute_ago = info[7]-60
    hour_ago = info[7]-(60*60)
    day_ago = info[7]-(60*60)*24
    week_ago = info[7]- 60*60*24*7
    month_ago = info[7]- 60*60*24*30
    year_ago = info[7]- 60*60*24*365

    times = [second_ago, minute_ago, hour_ago, day_ago, week_ago, month_ago, year_ago]
    i = 0
    editcount_bucket = [0] * 7 #this is 7 zeros in an array
    times.each do |time|
      xml2 = get_xml({:format => :xml, :action => :query, :list => :usercontribs, :ucuser => info[5], :ucstart => info[7].strftime("%Y-%m-%dT%H:%M:%SZ"), :ucend => time.strftime("%Y-%m-%dT%H:%M:%SZ"), :uclimit => 500})
      res2 = parse_xml(xml2)
      edits = res2.first['usercontribs'].first['item']
      if (edits != nil)
   	    editcount_bucket[i] = edits.length.to_i
      end
      i = i+1
    end

    #http://en.wikipedia.org/w/api.php?action=query&list=blocks&bkprop=id|user|by|timestamp|expiry|reason&bklimit=max&bkusers=Tisane 
    xml3 = get_xml({:format => :xml, :action => :query, :list => :blocks, :bkusers => info[5], :bklimit => :max, :bkprop => 'id|user|by|timestamp|expiry|reason' })
    res3 = parse_xml(xml3)
    blockinfo = res3.first['blocks'].first['block']
    blocktimes = 0
    if(blockinfo != nil)
	    blocktimes =  blockinfo.length.to_i
	    blockinfo = find_block_info(blockinfo)
    else
	    blockinfo = [] #empty array cause we ignore it above
    end
    
    usertalkpg_title = "User:"+info[5]
    xml4 = get_xml({:format => :xml, :action => :query, :prop => :revisions, :titles => usertalkpg_title, :rvprop => 'content'})
    res4 = parse_xml(xml4)
    
    source = nil
    if res4.first['pages'].first['page'].first['revisions'] != nil
      source = res4.first['pages'].first['page'].first['revisions'].first['rev'].first['content']
    end

    #Need to get info on rights
    
    [create, life, editcount.to_i] + editcount_bucket + [groups.to_s, blocktimes] + blockinfo + [source]
  end

  #block_id integer,
  #blocked_by string,
  #block_ts timestamp,
  #block_expiry timestamp,
  #block_reason text,
  def find_block_info blockinfo
    expiry = blockinfo.first['expiry']
    if (expiry == "infinity")
    	 expiry = nil
    else
      expiry = Time.parse(expiry)
    end
    [blockinfo.first['id'].to_i, blockinfo.first['by'].to_s, Time.parse(blockinfo.first['timestamp']), expiry, blockinfo.first['reason'].to_s]
  end
end
