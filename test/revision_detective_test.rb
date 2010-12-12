require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'revision_detective.rb'

require 'time'

class MediaWikiApiTest < Test::Unit::TestCase
  def setup
    @db = SQLite3::Database.new(":memory:")
    @db.execute('CREATE TABLE irc_wikimedia_org_en_wikipedia (
      id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text)')
    @detective = RevisionDetective.new(@db)
    @info = [1,
      'Amar Ben Belgacem',
      'M',
      '392473902',
      '391225974',
      'SD5',
      '+226',
      Time.parse('2010-02-10T22:17:39Z'),
      "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]"
    ]
  end
  
  def test_find_revision_info
    revinfo = @detective.find_revision_info(@info)
    assert_equal([Time.parse('Sat Oct 23 20:59:04 UTC 2010'), 'SD5', "fixes, added persondata, typos fixed: august 24 \342\206\222 August 24 using [[Project:AWB|AWB]]", 6776], [revinfo[0], revinfo[1], revinfo[2], revinfo[3]])
  end

end