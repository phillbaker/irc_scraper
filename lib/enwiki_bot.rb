require 'bot.rb'

require 'author_detective.rb'
require 'revision_detective.rb'
require 'page_detective.rb'
require 'external_link_detective.rb'

require 'rubygems'
require 'sqlite3'
require 'thread'
require 'digest/md5'
require 'ThreadPool.rb'
require 'logger'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db, :name
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME, db = nil)
    #server = 'irc.wikimedia.org' if server.nil?
    #channel = 'en.wikipedia' if channel.nil?
    #puts server + channel

    @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_') #TODO this isn't really sanitized...use URI.parse
    @error = Logger.new('log/bot.log') 
    @db_log = Logger.new('log/db.log')
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
    @name = bot_name
    
    #https://github.com/danielbush/ThreadPool for info on the threadpool
    @workers = ThreadPooling::ThreadPool.new(20)
    @db_queue = Queue.new
    #puts 'initial memory location: ' + @db_queue.to_s
    @db_results = {}
    start_db_worker()
    
    #Thread.abort_on_exception = true #set this so that if there's an exception on any of these threads, everything quits - good for initial debugging
    #@detectives = [RevisionDetective.new(@db), AuthorDetective.new(@db), ExternalLinkDetective.new(@db), PageDetective.new(@db)]
    @detectives = [RevisionDetective, AuthorDetective, ExternalLinkDetective, PageDetective]
    @detectives.each do |clazz|
      clazz.setup_table(@db)
    end
    
    super(bot_name)
  end
  
  def start_db_worker()
    db = db_open(@name)
    @workers.dispatch do
      loop do #keep this thread running forever
        #this works because even if we turn off working, we'll have stuff queued and we'll loop in the inner loop until the queue is cleared
        until @db_queue.empty? do
          #begin
            sql, key = @db_queue.pop()
            statement = db.prepare(sql)
            statement.execute!
            @db_log.error sql[11..20].strip if key == nil && #log 20 characters (baseically table) if there's no key(ie from detectives)
            #the value to reference the written value at
            if key #only do this if we need to return it
              id = db.get_first_value("SELECT last_insert_rowid()").to_s
              @db_results[key] = id
              #puts 'wrote id: ' + key.to_s + ' ' + id
            end
          #rescue Exception => e
          #  puts 'Exception: ' + e.to_s
          #  puts e.backtrace
          #ensure
            #puts 'done writing'
          #end
        end
      end
      #db.close unless db.closed?
    end
  end
  
  def hear(message)
    if should_store?(message)
      info = store!(message)
      #puts 'stored'
      #call our methods in other threads: Process.fork (=> actual system independent processes) or Thread.new = in ruby vm psuedo threads?
      ## so should the detective classes be static, so there's no chance of trying to access shared resources at the same time?
      #TODO build in some error handling/logging/queue to see if threads die/blow up and what we missed

      @detectives.each do |clazz|
        clues = info.dup
        @workers.dispatch do #on another thread
          #let's be careful passing around objects here, we need to make sure that if we modifying them on different threads, that's okay...
	        start_detective(clues,clazz,message)
        end
      end
    end
  end
  
  def start_detective(info, clazz, message)
    detective = clazz.new(@db_queue)
    #wait for this to be written to the db
    loop do
       break if @db_results[info.first]
    end
    id = @db_results[info.first]
    info[0] = id
    #mandatory wait period before investigating to allow wikipedia changes to propagate: 10s?
    sleep(10)
    begin
      detective.investigate(info)
    rescue Exception => e
      str = "EXCEPTION: sample id ##{info[0]} caused: #{e.message} at #{e.backtrace.find{|i| i =~ /_detective|mediawiki/} } with #{message}"
      @error.error str
      #Thread.current.kill
      exp = Exception.new(str)
      exp.set_backtrace(e.backtrace.select{|i| i =~ /_detective/ })
      raise exp
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
    
    key = db_write! [fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], time.to_i, fields[6]]
    
    #return the info used to create this so we can just pass them in code instead of querying the db
    [key, fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], time, fields[6]]
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
    db = SQLite3::Database.open("#{db_name}.#{DB_SUFFIX}")
    db.type_translation = true
    db.busy_timeout(1000) #in ms, 1000 = 1s
    db
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
    
    #deal with multiple threads writing to db
    key = Digest::MD5.hexdigest(Time.now.to_i.to_s + sql)
    @db_queue << [sql, key]
    key
    #return the primary id of the row that was created:
    #@db.get_first_value("SELECT last_insert_rowid()")
  end
  
end
  