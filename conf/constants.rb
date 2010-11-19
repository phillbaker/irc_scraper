BOT_NAME = 'ScraperBot'
REVISION_REGEX = /\00314\[\[\00307(.*)\00314\]\]\0034\ (.*)\00310\ \00302(.*)\003\ \0035\*\003\ \00303(.*)\003\ \0035\*\003\ \((.*)\)\ \00310(.*)\003/
TABLE_SCHEMA_PREFIX = 'CREATE TABLE ' #TODO this stuff doesn't belong here, create a new sql folder or something, there's going to be a bunch of tables
TABLE_SCHEMA_SUFFIX = <<-SQL
       (
      id integer primary key,
      article_name varchar(128) not null,
      desc varchar(8),
      url varchar(256),
      user varchar(64),
      byte_diff integer,
      ts timestamp(20),
      description text
    )
SQL
DB_SUFFIX = 'sqlite3'

PID_FILE_PATH = File.dirname(__FILE__) + '/../tmp/pid.txt'
IRC_LOG_DIR_PATH = File.dirname(__FILE__) + '/../log'

WIKI_API_SERVER = 'en.wikipedia.org' #no http:// and no trailing slash
WIKI_API_PATH = '/w/api.php' #leading slash

#with invisibles:  14[[07Amar Ben Belgacem14]]4 M10 02http://en.wikipedia.org/w/index.php?diff=392473902&oldid=391225974 5* 03SD5 5* (+226) 10fixes, added persondata, typos fixed: august 24 → August 24 using [[Project:AWB|AWB]]
