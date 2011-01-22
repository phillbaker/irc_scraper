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
    assert(Detective.table_exists?(@db, 'test_table_exists'))
  end
  
  def test_sql_prefix
    assert_equal("CREATE TABLE ".strip, Detective.sql_prefix.strip)
  end
  
  def test_sql_suffix
    #columns &= do 
    #  "id integer primary key,\n article_name varchar(128) not null"
    #end
    assert_equal("detective (id integer primary key,\n article_name varchar(128) not null)", Detective.sql_suffix(){"id integer primary key,\n article_name varchar(128) not null"}.strip)
    #assert(" detective (id integer primary key,\n article_name varchar(128) not null)", @detective.sql_suffix(&columns).strip)
  end
  
  def test_setup_sql
    s = Detective.sql_prefix() + Detective.sql_suffix()
    s.squeeze!
    assert_equal("CREATE TABLE detective (id integer primary key, value text)", s)
  end
  
  def test_setup_table
    Detective.setup_table(@db)
    assert(Detective.table_exists?(@db, Detective.table_name()))
  end
  
  def test_db_write!
    Detective.setup_table(@db)
    assert(1, @detective.db_write!(['id'], [1]))
  end
  
  def test_db_write_nulls
    Detective.setup_table(@db)
    assert(1, @detective.db_write!(['id', 'value'], [1, nil]))
  end
  
  def test_db_write_quotes
    Detective.setup_table(@db)
    assert(1, @detective.db_write!(['id', 'value'], [1, "te'xt"]))
    assert(2, @detective.db_write!(['id', 'value'], [2, "te''xt"]))
  end
  
end