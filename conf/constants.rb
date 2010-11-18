BOT_NAME = 'ScraperBot'
REVISION_REGEX = /\00314\[\[\00307(.*)\00314\]\]\0034\ (.*)\00310\ \00302(.*)\003\ \0035\*\003\ \00303(.*)\003\ \0035\*\003\ \((.*)\)\ \00310(.*)\003/
TABLE_SCHEMA_PREFIX = 'CREATE TABLE '
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

WIKI_API_URL = 'http://en.wikipedia.org/w/api.php'
