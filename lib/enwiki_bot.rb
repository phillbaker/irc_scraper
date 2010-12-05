require 'bot.rb'

require 'author_detective.rb'
require 'external_link_detective.rb'
require 'revision_detective.rb'
require 'page_detective.rb'

require 'rubygems'
require 'sqlite3'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME, db = nil)
    @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_') #TODO this isn't really sanitized...use URI.parse

    if db
      @db = db
      db_create_schema!(@table_name)
    elsif db_exists?(bot_name)
      #assume table has already been created, we're continuing from previous use
      db_open bot_name
    else
      @db = db_create!(bot_name)
      db_create_schema!(@table_name)
    end
    db_init
    
    @detectives = [AuthorDetective.new(@db), ExternalLinkDetective.new(@db), RevisionDetective.new(@db), PageDetective.new(@db)]
    
    super(bot_name)
  end
  
  def hear(message)
    if should_store? message
      info = store! message
      #TODO call our methods in other threads
      @detectives.each do |detective|
        detective.investigate(info)
      end
    end
  end
  
  def should_store? message
    #keep messages that match our format...eventually this will be limited to certain messages, should we spin out a thread per message?
    message =~ REVISION_REGEX #TODO this is silly, we should only scan this once...below, probably
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
    fields = process_irc(message)
    time = Time.now
    
    fields[2] = fields[2].to_i
    fields[3] = fields[3].to_i
    fields[5] = fields[5].to_i
    
    id = db_write! fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], time.to_i, fields[6]
    
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
    res = message.scan(REVISION_REGEX).first
    ids = res[2].scan(/diff=([0-9]+)&oldid=([0-9]+)/).first #parse the url to get the revid and the oldid
    res[2] = ids.last
    res.insert(2, ids.first)
    res
  end

  #keep this separate, if we switch to mysql, this will need to be a different implementation
  def db_exists? db_name
    File.exists? db_name
  end
  
  def db_create! db_name
    @db = SQLite3::Database.new("#{db_name}.#{DB_SUFFIX}")
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
    @db = SQLite3::Database.open("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_init
    @db.type_translation = true
  end
  
  def db_write! article_name, desc, rev_id, old_id, user, byte_diff, ts, description
    sql = %{
      INSERT INTO %s
      (article_name, desc, revision_id, old_id, user, byte_diff, ts, description)
      VALUES ('%s', '%s', '%d', %d, '%s', %d, %d, '%s')
    } % [@table_name, article_name, desc, rev_id, old_id, user, byte_diff, ts, description]
    statement = @db.prepare(sql)
    statement.execute!
    
    #return the primary id of the row that was created:
    @db.get_first_value("SELECT last_insert_rowid()")
  end
  
end
  