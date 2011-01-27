require 'bot.rb'

require 'author_detective.rb'
require 'revision_detective.rb'
require 'page_detective.rb'
require 'external_link_detective.rb'
require 'mediawiki_api.rb'

require 'rubygems'
require 'sqlite3'
require 'thread'
require 'digest/md5'
require 'ThreadPool.rb'
require 'logger'

require 'bundler/setup'
require 'nokogiri'

class EnWikiBot < Bot #TODO db.close
  
  attr_accessor :db, :name
  
  def initialize(server, port, channel, password = '', bot_name = BOT_NAME, db = nil)
    #server = 'irc.wikimedia.org' if server.nil?
    #channel = 'en.wikipedia' if channel.nil?
    #puts server + channel

    @table_name = server.gsub(/\./, '_') + '_' + channel.gsub(/\./, '_') #TODO this isn't really sanitized...use URI.parse
    @error = Logger.new('log/bot.log') 
    @db_log = Logger.new('log/db.log')
    #@db_log_main = Logger.new('log/db_main.log')
    #@db_log_link = Logger.new('log/link.log')
    @irc_log = Logger.new('log/feed.log')
    if db
      @db = db
      db_create_schema!(@table_name)
    elsif db_exists?(bot_name)
      #assume table has already been created, we're continuing from previous use
      @db = db_open(bot_name)
    else
      @db = db_create!(bot_name)
      db_create_schema!(@table_name)
    end
    @name = bot_name
    
    #https://github.com/danielbush/ThreadPool for info on the threadpool
    @workers = ThreadPooling::ThreadPool.new(250) #base this on a rough guesstimate of how many seconds of work we get per second
    @db_queue = Queue.new
    #puts 'initial memory location: ' + @db_queue.to_s
    start_db_worker()
    
    #Thread.abort_on_exception = true #set this so that if there's an exception on any of these threads, everything quits - good for initial debugging
    #@detectives = [RevisionDetective, AuthorDetective, ExternalLinkDetective, PageDetective]
    @detectives = [ExternalLinkDetective]
    @detectives.each do |clazz|
      clazz.setup_table(@db)
    end
    
    super(bot_name)
  end
  
  def start_db_worker()
    db = db_open(@name)
    @workers.dispatch do
      loop do #keep this thread running forever
        #this works because even if we turn off working, we'll have stuff queued and we'll loop in the inner loop until the queue is cleared
        until @db_queue.empty? do
          begin
            sql, key = @db_queue.pop()
            statement = db.prepare(sql)
            statement.execute!
            #db_log is NOT threadsafe! that stuff write at different times to the file!
            #@db_log.info sql[11..20].strip if key == nil #log 20 characters (baseically table) if there's no key(ie from detectives)
            #@db_log_main.info sql[11..20].strip unless key == nil
            #@db_log.info "insert length = #{sql.length}; queue length = #{@db_queue.size}" if key == nil && sql[11..20] =~ /link/
          rescue SQLite3::SQLException, Exception => e
            @db_log.error sql
            @db_log.error e
            begin
              require 'net/smtp'

              Net::SMTP.start('localhost') do |smtp|
                smtp.send_message(
                  "Something's gone wrong with our project! This is an automated message, but check db.log. #{Time.now.to_s}", 
                  'senior_design@retrodict.com', 
                  ['me@retrodict.com', 'brittney.exline@gmail.com', '']
                )
              end
            rescue Errno::ECONNREFUSED
              #we couldn't connect
            end
            #@db_log.error e.backtrace
            #puts 'Exception: ' + e.to_s
            #puts e.backtrace
          #ensure
            #puts 'done writing'
          end
        end
      end
      #db.close unless db.closed?
    end
  end
  
  def hear(message)
    if should_store?(message)
      info, size = store!(message)
      #@irc_log.info("#{size} - #{message[0..100]}")
      #puts 'stored'
      #call our methods in other threads: Process.fork (=> actual system independent processes) or Thread.new = in ruby vm psuedo threads?
      ## so should the detective classes be static, so there's no chance of trying to access shared resources at the same time?
      #TODO build in some error handling/logging/queue to see if threads die/blow up and what we missed
      if should_follow?(info[0])
        #do the rest of this on threads - it could be slow, don't block
        @workers.dispatch do
          data = get_diff_data(info[2])
          links = find_links(data.first)
          
          unless links.empty?
            @irc_log.info("following: #{links.size.to_s}; #{info[0]}")
            @detectives.each do |clazz|
              clues = info + data + [links] #this should return copies of each of this, we don't want to pass around the original objects on different threads
              @workers.dispatch do #on another thread
                #let's be careful passing around objects here, we need to make sure that if we modifying them on different threads, that's okay...
      	        start_detective(clues,clazz,message)
              end #end detective dispatch
            end #end of detectives.each
          else
            @irc_log.info('not following: no links')
          end #end of unless
        end #end of following dispatch
      else
        @irc_log.info('not following: wrong namespace ')
      end #end of if follow
    end #end of should_store?
  end
  
  #determines if there's at least 1 link in the revision
  #returns diff text, 
  def find_links xml_diff_unescaped
    diff_html = CGI.unescapeHTML(xml_diff_unescaped)
    noked = Nokogiri.HTML(diff_html)
    linkarray = []
    noked.css('.diff-addedline').each do |td| #TODO should probably be looking specifically at .diffchange children for added text within the line
      revision_line = Nokogiri.HTML(CGI.unescapeHTML(td.children.to_s)).css('div').children
      #http://daringfireball.net/2010/07/improved_regex_for_matching_urls
      #%r{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}
      url = %r{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))}x
      #based on http://www.mediawiki.org/wiki/Markup_spec/BNF/Links
      external_link_regex = /\[(#{url}\s*(.*?))\]/
      #TOOD only look at text in the .diffchange
      #TODO pull any correctly formed links in the diff text
      #TODO on longer revisions, this regex takes FOREVER! need to simplify!
      #TODO test this on pages with multiple links...
      res = revision_line.to_s.scan(external_link_regex) 
      if res.size > 0
        #p res
        res = res.first.compact
        #["http://www.eyemagazine.com/feature.php?id=62&amp;fid=270 Designing heroes", "http://www.eyemagazine.com/feature.php?id=62&amp;fid=270", "Designing heroes"]
        linkarray << [res[1], #link
                      res[2]] #description
      end
    end
    linkarray
  end
  
  def get_diff_data rev_id
    #http://en.wikipedia.org/w/api.php?action=query&prop=revisions&revids=363492332&rvdiffto=prev&rvprop=ids|flags|timestamp|user|size|comment|parsedcomment|tags|flagged
    xml = get_xml({:format => :xml, :action => :query, :prop => :revisions, :revids => rev_id, :rvdiffto => 'prev', :rvprop => 'ids|flags|timestamp|user|size|comment|parsedcomment|tags|flagged' })
    noked = Nokogiri.XML(xml)
    attrs = {}
    #page attributes
    # pageid = 
    # ns = 
    # title = 
    # tags = 
    noked.css('page').first.attributes.each do |k,v|
      attrs[v.name] = v.value
    end
    
    #rev attributes
    # revid
    # parentid
    # minor
    # user
    # timestamp
    # size
    # comment
    noked.css('rev').first.attributes.each do |k,v|
      attrs[v.name] = v.value
    end
    
    #tags
    tags = []
    noked.css('tags').children.each do |child|
      tags << child.children.to_s
    end
    
    #diff attributes
    diff_elem = noked.css('diff')
    diff_elem.first.attributes.each do |k,v|
      attrs[v.name] = v.value
    end
    diff = diff_elem.children.to_s
    
    [diff, attrs, tags]
  end
  
  #look at title, exclude titles starting with: User talk, Talk, Wikipedia, User, etc.
  def should_follow? article_title 
    bad_beg_regex = /^(Talk:|User:|User\stalk:|Wikipedia:|Wikipedia\stalk:|File\stalk:|MediaWiki:|MediaWiki\stalk:|Template\stalk:|Help:|Help\stalk:|Category\stalk:|Thread:|Thread\stalk:|Summary\stalk:|Portal\stalk:|Book\stalk:|Special:|Media:)/
    !(article_title =~ bad_beg_regex)
  end
  
  #clues:
  # 0: article_name (string), 
  # 1: desc (string), 
  # 2: rev_id (string),
  # 3: old_id (string)
  # 4: user (string), 
  # 5: byte_diff (int), 
  # 6: description (string)
  # 7: diff_unescaped_xml (string)
  # 8: attributes from call: user, timestamp, revid, size, title, from, to, parentid, anon, ns, space, pageid
  # 9: tags (Array)
  # 10: array of array of links found in [url, desc] format, description may be nil if it was not a wikilink
  def start_detective(clues, clazz, message)
    detective = clazz.new(@db_queue)
    #mandatory wait period before investigating to allow wikipedia changes to propagate: => time we kill hitting wikipedia for external link stuff
    begin
      detective.investigate(clues)
    rescue Exception => e
      str = "EXCEPTION: sample id ##{info[0]} caused: #{e.message} at #{e.backtrace.find{|i| i =~ /_detective|mediawiki/} } with #{message}"
      @error.error str
      exp = Exception.new(str)
      exp.set_backtrace(e.backtrace.select{|i| i =~ /_detective/ })
      raise exp
    end
  end

  def should_store? message
    #keep messages that match our format...eventually this will be limited to certain messages, should we spin out a thread per message?
    message =~ /\00314\[\[\00307(.*)\00314\]\]\0034\ (.*)\00310\ \00302(.*)\003\ \0035\*\003\ \00303(.*)\003\ \0035\*\003\ \((.*)\)\ \00310(.*)\003/ #TODO this is silly, we should only scan this once...below, probably
  end
  
  #fields in the return:
  # 0: article_name (string), 
  # 1: desc (string), 
  # 2: rev_id (string),
  # 3: old_id (string)
  # 4: user (string), 
  # 5: byte_diff (int), 
  # 6: description (string)
  def store! message
    fields = []
    fields = process_irc(message)
    #TODO for some reason, a bunch of messages get cut off and we don't get the entire thing...but then it shouldn't appear here...the regexp above should clear it...
    raise Exception.new("ERROR: message didn't parse") if fields == nil
    
    fields[2] = fields[2].to_i
    fields[3] = fields[3].to_i
    fields[5] = fields[5].to_i
    
    size = db_queue(fields)
    
    #return the info used to create this so we can just pass them in code instead of querying the db
    [fields, size]
  end

  #given the irc announcement in the irc monitoring channel for en.wikipedia, this returns the different fields
  # 0: article_name (string), 
  # 1: desc (string), 
  # 2: rev_id (string),
  # 3: old_id (string)
  # 4: user (string), 
  # 5: byte_diff (string), 
  # 6: description (string)
  def process_irc message
    res = message.scan(/\00314\[\[\00307(.*)\00314\]\]\0034\s+(.*)\00310\s+\00302.*(diff|oldid)=([0-9]+)&(oldid|rcid)=([0-9]+)\s*\003\s*\0035\*\003\s*\00303(.*)\003\s*\0035\*\003\s*\((.*)\)\s*\00310(.*)\003/).first
    #get rid of the diff/oldid and oldid/rcid groups
    res.delete_at(4)
    res.delete_at(2)
    res
  end

  #keep this separate, if we switch to mysql, this will need to be a different implementation
  def db_exists? db_name
    File.exists? db_name
  end
  
  def db_create! db_name
    SQLite3::Database.new("#{db_name}.#{DB_SUFFIX}")
  end
  
  def db_create_schema! table_name
    unless db_table_exists? table_name
      @db.execute_batch(TABLE_SCHEMA_PREFIX + table_name + TABLE_SCHEMA_SUFFIX)
    end
  end
  
  def db_table_exists? table_name
    !@db.table_info(table_name).empty?
  end
  
  def db_open db_name
    db = SQLite3::Database.open("#{db_name}.#{DB_SUFFIX}")
    db.type_translation = true
    db.busy_timeout(1000) #in ms, 1000 = 1s
    db
  end
  
  #args should be: article_name, desc, rev_id, old_id, user, byte_diff, ts, description
  def db_queue args
    #TODO put this in rescue blocks so that if something chokes, we don't completely die, and put in a new table (or maybe a column for logging errors?)
    args.collect! do |o|
      o.is_a?(String) ? SQLite3::Database.quote(o) : o
    end
    
    sql = %{
      INSERT INTO %s
      (article_name, desc, revision_id, old_id, user, byte_diff, description)
      VALUES ('%s', '%s', '%d', %d, '%s', %d, '%s')
    } % ([@table_name] + args)#article_name, desc, rev_id, old_id, user, byte_diff, ts, description
    
    @db_queue << sql
    @db_queue.size
  end
  
end
  