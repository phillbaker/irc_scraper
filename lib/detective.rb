require 'rubygems'
require 'sqlite3'

class Detective
  attr_accessor :db
  
  def initialize db
    @db = db
  end
  
  def table_name
    # To be defined in subclasses
    #TODO should this be empty? or NotImplementedYet error?
    'detective'
  end

  #return a proc that defines the columns used by this detective
  def columns
    Proc.new do
      "id integer primary key"
    end
  end

  #main entry method for this class
  #should call db_write! to put results discovered during the investigation into the table
  #info is a list of primary_id, article_name, desc, url, user, byte_diff, timestamp, description
  def investigate info
    raise NotImplementedError
  end
  
  #columns should be a list of strings of the names of the columns that data will be inserted into
  #data should be a list of the data, in the same order as the named columns in columns
  def db_write! columns, data
    column_sql = columns.join(', ')
    #wrap string data types in single quotes, otherwise let it be (ie Numeric should stay numeric)
    data_quoted = data.collect do |o|
      o.is_a?(String) ? "'#{o}'" : o
    end
    data_sql = data_quoted.join(', ')
    sql = %{INSERT INTO %s ( %s ) VALUES ( %s ) } % [table_name(), column_sql, data_sql]
    statement = @db.prepare(sql)
    statement.execute!
    
    #return the primary id of the row that was created:
    @db.get_first_value("SELECT last_insert_rowid()")
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
  
  def setup_table
    unless table_exists? table_name()
      @db.execute_batch(sql_prefix() + sql_suffix())
    end
  end
  
  def table_exists? name
    #sqlite specific...
    @db.get_first_value("SELECT name FROM sqlite_master WHERE name='" + name + "'")
  end
end