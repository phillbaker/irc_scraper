require 'bot.rb'

require 'author_detective.rb'
require 'page_detective.rb'
require 'revision_detective.rb'
#require 'external_link_detective.rb' #TODO

require 'rubygems'
require 'sqlite3'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME)
    if db_exists? bot_name #TODO this really isn't clean
      db_open bot_name
    else
      @db = db_create!(bot_name)
      @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_') #TODO this isn't really sanitized...use URI.parse
      db_create_schema! @table_name 
    end
    db_init
    
    @detectives = [AuthorDetective.new(@db), PageDetective.new(@db), RevisionDetective.new(@db)]
    
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
  
  #returns primary_id (string), article_name (string), desc (string), url (string), user (string), byte_diff (int), timestamp (Time object), description (string)
  def store! message
    fields = process_irc(message)
    time = Time.now
    fields[4] = fields[4].to_i #convert the byte diff to an int
    id = db_write! fields[0], fields[1], fields[2], fields[3], fields[4], time.to_i, fields[5]
    
    #return the info used to create this so we can just pass them in code instead of querying the db
    [id, fields[0], fields[1], fields[2], fields[3], fields[4], time, fields[5]]
  end

  #given the irc announcement in the irc monitoring channel for en.wikipedia, this returns the different fields
  def process_irc message
    message.scan(REVISION_REGEX).first
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
  
  #article_name (string), desc (string), url (string), user (string), byte_diff int, ts (int), description
  def db_write! article_name, desc, url, user, byte_diff, ts, description
    statement = @db.prepare( %{
      INSERT INTO %s
      (article_name, desc, url, user, byte_diff, ts, description)
      VALUES ('%s', '%s', '%s', '%s', %d, %d, '%s')
    } % [@table_name, article_name, desc, url, user, byte_diff, ts, description] )
    statement.execute!
    
    #return the primary id of the row that was created:
    @db.get_first_value("SELECT last_insert_rowid()")
  end
  
end
  