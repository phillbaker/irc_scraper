require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'detective.rb'

class DetectiveTest < Test::Unit::TestCase
  
  def setup
    #create in-memory sqlitedb
    @db = SQLite3::Database.new(":memory:")
    @detective = Detective.new(@db)
  end
  
  def test_table_exists?
    @db.execute('create table test_table_exists (id integer primary key, data varchar(128))')
    #@db.get_first_value('select name from sqlite_master;')
    assert(@detective.table_exists?('test_table_exists'))
  end
  
  def test_sql_prefix
    assert("CREATE TABLE ".strip, @detective.sql_prefix.strip)
  end
  
  def test_sql_suffix
    #columns &= do 
    #  "id integer primary key,\n article_name varchar(128) not null"
    #end
    assert(" detective (id integer primary key,\n article_name varchar(128) not null)", @detective.sql_suffix(){"id integer primary key,\n article_name varchar(128) not null"}.strip)
    #assert(" detective (id integer primary key,\n article_name varchar(128) not null)", @detective.sql_suffix(&columns).strip)
  end
  
end