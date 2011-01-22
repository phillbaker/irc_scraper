require 'rubygems'
require 'sqlite3'

class Detective
  class << self
    def table_name
      # To be defined in subclasses
      #TODO should this be empty? or NotImplementedYet error?
      'detective'
    end

    #return a proc that defines the columns used by this detective
    def columns
      Proc.new do
        "id integer primary key, value text"
      end
    end

    def sql_prefix
      "CREATE TABLE "
    end

    #By default calls the proc returned by the #columns() method
    #Pass an optional block expected to return a string of the column definitions
    def sql_suffix #&cols
      cols = block_given? ? yield : columns().call
      " #{table_name()} (#{cols})"
    end

    def setup_table db
      unless table_exists?(db, table_name())
        db.execute_batch(sql_prefix() + sql_suffix())
      end
    end

    def table_exists? db, name
      #sqlite specific...
      db.get_first_value("SELECT name FROM sqlite_master WHERE name='" + name + "'")
    end
  end #end class methods
  
  attr_accessor :db
  
  def initialize db
    @db = db
  end
  
  #main entry method for this class
  #should call db_write! to put results discovered during the investigation into the table
  #info is a list of primary_id, article_name, desc, rev_id (string), old_id (string), user, byte_diff, timestamp, description
  def investigate info
    raise NotImplementedError
  end
  
  #columns should be a list of strings of the names of the columns that data will be inserted into
  #data should be a list of the data, in the same order as the named columns in columns
  def db_write! columns, data
    column_sql = columns.join(', ')
    #wrap string data types in single quotes, otherwise let it be (ie Numeric should stay numeric)
    data_quoted = data.collect do |o|
      ret = o
      if o.is_a?(String)
        o = SQLite3::Database.quote(o) #need to escape single quotes, not c-style for sqlite, but two single quotes
        ret = "'#{o}'"
      elsif o == nil
        ret = 'NULL'
      end
      ret
    end
    data_sql = data_quoted.join(', ')
    sql = %{INSERT INTO %s ( %s ) VALUES ( %s ) } % [self.class.table_name(), column_sql, data_sql]
    statement = @db.prepare(sql)
    
    #deal with multiple threads writing to db
    try_again = 0
    begin
      statement.execute!
    rescue Sqlite3Error => e
      raise unless e.message =~ /locked/ || e.message =~ /busy/

      if try_again < 5
        try_again += 1
        retry
      else
        raise
      end
    end
  end
end