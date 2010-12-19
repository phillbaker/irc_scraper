require 'rubygems'
require 'sqlite3'

#path from current working directory invocation of the script, not the location of the script itself
db = SQLite3::Database.open('ScraperBot.sqlite3.20101219.bak') 
first_ts = db.get_first_value('select ts from irc_wikimedia_org_en_wikipedia where id = 1')
samples = db.get_first_value('select count(*) from irc_wikimedia_org_en_wikipedia')
last_ts = db.get_first_value('select ts from irc_wikimedia_org_en_wikipedia where id = ' + total)
bucket_width = first_ts - last_ts

#divide the total time that revisions have been collected into 10 buckets
#find the number of revisions that have been added to the db during each of those buckets
#the running sum is the total that we had as of each time period

#look at the counts for each table, and other stats...
#look at counts of specific items: good link additions, bad link additions

#http://chart.apis.google.com/chart?chs=440x220&cht=lxy&chd=t:0,10,20,40,80,90,95,99|0,20,30,40,50,60,70,80&chdl=Unicorns&chxt=x,y&chtt=unicorns+over+time&chxl=0:|1|2|3|4|5|6|7|8|9

#puts "first ts: #{first}; total: #{total}; last ts: #{last}"

