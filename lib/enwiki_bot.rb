require 'bot.rb'
require 'rubygems'
require 'sqlite3'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME)
    if db_exists? bot_name
      db_open bot_name
    else
      @db = db_create!(bot_name)
      @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_')
      db_create_schema! @table_name 
    end
    db_init
    
    super(bot_name)
  end
  
  def hear(message)
    if should_store? message
      store! message
      #say message
    end
  end
  
  def should_store? message
    #keep messages that match our format...eventually this will be limited to certain messages, should we spin out a thread per message?
    message =~ REVISION_REGEX
  end
  
  def store! message
    fields = message.scan(REVISION_REGEX).first
    db_write! fields[0], fields[1], fields[2], fields[3], fields [4].to_i, Time.now.to_i, fields[5]
  end

  def db_exists? db_name
    File.exists? db_name
  end
  
  def db_create! db_name
    @db = SQLite3::Database.new("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_create_schema! table_name
    if @db.table_info(table_name).empty?
      @db.execute_batch(TABLE_SCHEMA_PREFIX + table_name + TABLE_SCHEMA_SUFFIX)
    end
  end
  
  def db_open db_name
    @db = SQLite3::Database.open("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_init
    @db.type_translation = true
  end
  
  def db_write! article_name, desc, url, user, byte_diff, ts, description
    @db.execute( %{
      INSERT INTO %s
      (article_name, desc, url, user, byte_diff, ts, description)
      VALUES ('%s', '%s', '%s', '%s', %d, %d, '%s')
    } % [@table_name, article_name, desc, url, user, byte_diff, ts, description] )
  end
  
end
  