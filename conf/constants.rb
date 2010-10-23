BOT_NAME = 'ScraperBot'
REVISION_REGEX = /\[\[([a-zA-Z\-_\ ]+)\]\]\ ([A-Z]+)\ ([a-zA-Z\.:\/\?=0-9&]+)\ \*\ ([a-zA-Z\-_\.]+)\ \*\ \(([0-9\-\+]+)\)\ (.*)/
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

=begin
CREATE TABLE test_table (
  id integer primary key,
  article_name varchar(128) not null,
  desc varchar(8),
  url varchar(256),
  user varchar(64),
  byte_diff integer,
  ts timestamp(20),
  description text
)

insert into test_table (article_name, desc, url, user, byte_diff, ts, description) values ('Hull speed', 'M', 'http://en.wikipedia.org/w/index.php?diff=392131752&oldid=387821239', 'Mark.camp', 26, 1287708813, 'Reworded sentences in intro that exaggerated slightly the contribution of wave interference to total wave drag.');

"[[Jean-Cyril Spinetta]] MB http://en.wikipedia.org/w/index.php?diff=392133710&oldid=379581588 * RjwilmsiBot * (+228) /* References */Adding Persondata using [[Project:AWB|AWB]] (7307)"
.scan(/\[\[([a-zA-Z\-_\ ]+)\]\]\ ([A-Z]+)\ ([a-zA-Z\.:\/\?=0-9&]+)\ \*\ ([a-zA-Z\-_\.]+)\ \*\ \(([0-9\-\+]+)\)\ (.*)/).first
=end
