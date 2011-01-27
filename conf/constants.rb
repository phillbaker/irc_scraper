BOT_NAME = 'EnWikiScraperBot'

DB_SUFFIX = 'sqlite3'
TABLE_SCHEMA_PREFIX = 'CREATE TABLE ' #TODO this stuff doesn't belong here, create a new sql folder or something, there's going to be a bunch of tables
TABLE_SCHEMA_SUFFIX = <<-SQL
       (
      id integer primary key autoincrement,
      article_name varchar(128) not null,
      desc varchar(8),
      revision_id integer,
      old_id integer,
      user varchar(64),
      byte_diff integer,
      description text,
      created DATE DEFAULT (datetime('now','localtime'))
    )
SQL

PID_FILE_PATH = File.dirname(__FILE__) + '/../tmp/pid.txt'
IRC_LOG_DIR_PATH = File.dirname(__FILE__) + '/../log'

WIKI_API_SERVER = 'en.wikipedia.org' #no http:// and no trailing slash #TODO just keep this in one and to URI.parse(url).
WIKI_API_PATH = '/w/api.php' #leading slash
