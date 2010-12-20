require 'rubygems'
require 'sqlite3'

#path from current working directory invocation of the script, not the location of the script itself
db = SQLite3::Database.open('ScraperBot.sqlite3.20101219.bak') 
first_ts = db.get_first_value('select ts from irc_wikimedia_org_en_wikipedia where id = 1').to_i
num_samples = db.get_first_value('select count(*) from irc_wikimedia_org_en_wikipedia').to_i
last_ts = db.get_first_value('select ts from irc_wikimedia_org_en_wikipedia where id = ' + num_samples.to_s).to_i

#divide the total time that revisions have been collected into 10 buckets (alright 11 with the initial 0)
bucket_width = (last_ts - first_ts)/10 #approximation...

#find the number of revisions that have been added to the db during each of those buckets
counts = [0] #start with 0 at the beginning, running sum of collected samples
times = [first_ts]
(1..10).each do |i|
  time = first_ts + bucket_width * i
  times << time
  #the running sum is the total that we had as of each time period
  counts << num_samples = db.get_first_value('select count(*) from irc_wikimedia_org_en_wikipedia where ts <= ' + time.to_s).to_i
end

#times.each_with_index do |o,i|
#  puts "#{o} | #{counts[i]}"
#end

#puts "first ts: #{first_ts}; total: #{num_samples}; last ts: #{last_ts}"

#
url = "http://chart.apis.google.com/chart?" + 
  "cht=lc" + #lxy" + 
  "&chs=440x220" +
  "&chd=t:" + counts.join(',') + #"&chd=t:0,10,20,40,80,90,95,99|0,20,30,40,50,60,70,80" + 
  "&chdl=Wikipedia Revision Samples" + 
  "&chxt=x,y" + 
  "&chtt=" + "Samples over time".gsub(/\ /, '+') +
  "&chxr=1,0," + num_samples.to_s +
  "&chds=0," + num_samples.to_s +
  "&chxl=0:|#{Time.at(times.first).strftime("%b %d %Y %H:%M")}|#{Time.at(times[5]).strftime("%b %d %Y")}|#{Time.at(times.last).strftime("%b %d %Y %H:%M")}" #"&chxl=0:|0|1|2|3|4|5|6|7|8|9|10"

#puts url

puts 'Content-type: text/html'
puts "<html><head><title>Spam Detection on Wikipedia stats page</title></head><body><h1>Spam Detection on Wikipedia SummaryStatistics</h1><p><img src=\"#{url}\"/></p></body><!--I see you!--></html>"

#TODO look at the counts for each table, and other stats...
#look at namespace 0 revisions specifically (and in templates? (namespace 10?))
#TODO look at counts of specific items: good link additions, bad link additions





