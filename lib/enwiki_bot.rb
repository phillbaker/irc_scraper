require 'bot.rb'

require 'author_detective.rb'
require 'revision_detective.rb'
require 'page_detective.rb'
require 'external_link_detective.rb'

require 'rubygems'
require 'sqlite3'

require 'threadpool'
require 'logger'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME, db = nil)
    #server = 'irc.wikimedia.org' if server.nil?
    #channel = 'en.wikipedia' if channel.nil?
    #puts server + channel
    
    @pool = ThreadPool.new(20) # up to 10 threads
    #http://snippets.dzone.com/posts/show/3276 for info on the threadpool
    #need to call pool.join() before closing the db

    @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_') #TODO this isn't really sanitized...use URI.parse
    log = Logger.new('errors.log') 
    if db
      @db = db
      db_create_schema!(@table_name)
    elsif db_exists?(bot_name)
      #assume table has already been created, we're continuing from previous use
      @db = db_open(bot_name)
    else
      @db = db_create!(bot_name)
      db_create_schema!(@table_name)
    end
    db_init()
    
    #Thread.abort_on_exception = true #set this so that if there's an exception on any of these threads, everything quits - good for initial debugging
    #@detectives = [RevisionDetective.new(@db), AuthorDetective.new(@db), ExternalLinkDetective.new(@db), PageDetective.new(@db)]
    @detectives = [RevisionDetective, AuthorDetective, ExternalLinkDetective, PageDetective]
    @detectives.each do |clazz|
      clazz.setup_table(@db)
    end
    
    super(bot_name)
  end
  
  def hear(message)
    if should_store?(message)
      info = store!(message)
      #call our methods in other threads: Process.fork (=> actual system independent processes) or Thread.new = in ruby vm psuedo threads?
      ## so should the detective classes be static, so there's no chance of trying to access shared resources at the same time?
      #TODO build in some error handling/logging/queue to see if threads die/blow up and what we missed

      @detectives.each do |clazz|
        @pool.process{ start_detective(info,clazz,message) }
      end
    end
  end
  
  def start_detective(info, clazz, message)
      db = db_open(@name)
      detective = clazz.new(db)
      #mandatory wait period before investigating: 10s?
      sleep(10)
      begin
        detective.investigate(info)
      rescue Exception => e
        exp = Exception.new("EXCEPTION: sample id ##{info[0]} caused: #{e.message} at #{e.backtrace.find{|i| i =~ /_detective/} } with #{message}") #.find{|i| i =~ /^(.|\/[^SL])/}  
        exp.set_backtrace(e.backtrace.select{|i| i =~ /_detective/ })
        raise exp
      rescue TypeError => e
        raise Exception.new("ERROR: sample id ##{info[0]} caused: #{e.message} at #{e.backtrace.first}")
      end
  end

  def should_store? message
    #keep messages that match our format...eventually this will be limited to certain messages, should we spin out a thread per message?
    message =~ /\00314\[\[\00307(.*)\00314\]\]\0034\ (.*)\00310\ \00302(.*)\003\ \0035\*\003\ \00303(.*)\003\ \0035\*\003\ \((.*)\)\ \00310(.*)\003/ #TODO this is silly, we should only scan this once...below, probably
  end
  
  #returns:
  # 0: sample_id (string), 
  # 1: article_name (string), 
  # 2: desc (string), 
  # 3: rev_id (string),
  # 4: old_id (string)
  # 5: user (string), 
  # 6: byte_diff (int), 
  # 7: timestamp (Time object), 
  # 8: description (string)
  def store! message
    fields = []
    fields = process_irc(message)
    #TODO for some reason, a bunch of messages get cut off and we don't get the entire thing...but then it shouldn't appear here...the regexp above should clear it...
    raise Exception.new("ERROR: message didn't parse") if fields == nil
    
    time = Time.now
    
    fields[2] = fields[2].to_i
    fields[3] = fields[3].to_i
    fields[5] = fields[5].to_i
    
    id = db_write! [fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], time.to_i, fields[6]]
    
    #return the info used to create this so we can just pass them in code instead of querying the db
    [id.to_i, fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], time, fields[6]]
  end

  #given the irc announcement in the irc monitoring channel for en.wikipedia, this returns the different fields
  # 0: article_name (string), 
  # 1: desc (string), 
  # 2: rev_id (string),
  # 3: old_id (string)
  # 4: user (string), 
  # 5: byte_diff (string), 
  # 6: description (string)
  def process_irc message
    res = message.scan(/\00314\[\[\00307(.*)\00314\]\]\0034\s+(.*)\00310\s+\00302.*(diff|oldid)=([0-9]+)&(oldid|rcid)=([0-9]+)\s*\003\s*\0035\*\003\s*\00303(.*)\003\s*\0035\*\003\s*\((.*)\)\s*\00310(.*)\003/).first
    #get rid of the diff/oldid and oldid/rcid groups
    res.delete_at(4)
    res.delete_at(2)
    res
  end

  #keep this separate, if we switch to mysql, this will need to be a different implementation
  def db_exists? db_name
    File.exists? db_name
  end
  
  def db_create! db_name
    SQLite3::Database.new("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_create_schema! table_name
    unless db_table_exists? table_name
      @db.execute_batch(TABLE_SCHEMA_PREFIX + table_name + TABLE_SCHEMA_SUFFIX)
    end
  end
  
  def db_table_exists? table_name
    !@db.table_info(table_name).empty?
  end
  
  def db_open db_name
    SQLite3::Database.open("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_init
    @db.type_translation = true
    @db.busy_timeout(1000) #in ms, 1000 = 1s
  end
  
  #args should be: article_name, desc, rev_id, old_id, user, byte_diff, ts, description
  def db_write! args
    #TODO put this in rescue blocks so that if something chokes, we don't completely die, and put in a new table (or maybe a column for logging errors?)
    args.collect! do |o|
      o.is_a?(String) ? SQLite3::Database.quote(o) : o
    end
    
    sql = %{
      INSERT INTO %s
      (article_name, desc, revision_id, old_id, user, byte_diff, ts, description)
      VALUES ('%s', '%s', '%d', %d, '%s', %d, %d, '%s')
    } % ([@table_name] + args)#article_name, desc, rev_id, old_id, user, byte_diff, ts, description
    statement = @db.prepare(sql)
    statement.execute!
    
    #return the primary id of the row that was created:
    @db.get_first_value("SELECT last_insert_rowid()")
  end
  
end
  