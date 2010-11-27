require 'rubygems'
require 'sqlite3'

class Detective
  attr_accessor :db
  
  def initialize db
    @db = db
    #setup_table() unless table_exists? table_name()
  end
  
  def sql_prefix
    "CREATE TABLE "
  end
  
  def sql_suffix &columns
    " #{table_name()} (#{columns})"
  end
  
  def table_name
    # To be defined in subclasses
    #TODO should this be empty?
    'detective'
  end

  #main entry method for this class
  def investigate info
    raise NotImplementedError
  end
  
  def setup_table
    unless db_table_exists? table_name
      @db.execute_batch(sql_prefix() + table_name() + sql_suffix())
    end
  end
  
  #sqlite specific...
  def table_exists? name
    @db.get_first_value("SELECT name FROM sqlite_master WHERE name='" + name + "'")
  end
end