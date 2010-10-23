#!/usr/bin/env ruby
# == Synopsis
#
# start.rb: Starts up a JoCoBot and connects it to a specified IRC server and channel
#
# == Usage
#
# ruby start.rb OPTIONS
#
# -h, --help:
#    show help
#
# --server hostname, -s hostname:
#    required, the hostname of the server to connect to 
#
# --channel name, -c name:
#    required, the name of the channel to connect to 
# 
# --port number, -p port:
#    the port of the server to connect to, defaults to 6667
#
# --password word, -P word:
#    the password of the server to connect to, if necessary

require File.dirname(__FILE__) + '/../conf/include'
require 'enwiki_bot'
require 'irc_client.rb'
require 'getoptlong'
require 'rdoc/usage'

IRC_LOG_FILE_PATH = IRC_LOG_DIR_PATH + '/bin.log'

opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    ['--server', '-s', GetoptLong::REQUIRED_ARGUMENT],
    ['--channel', '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--port', '-p', GetoptLong::OPTIONAL_ARGUMENT],
    ['--password', '-P', GetoptLong::OPTIONAL_ARGUMENT]
  )
server = nil
channel = nil
port = 6667
password = nil
opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
      exit(0)
    when '--server'
      server = arg
    when '--channel'
      channel = arg
    when '--port'
      port = arg.to_i
    when '--password'
      password = arg
  end
end
if server.nil? 
  puts "The required --server parameter was missing."
  RDoc::usage
elsif channel.nil?
  puts "The required --channel parameter was missing."
  RDoc::usage
end
if File.exist?(PID_FILE_PATH)
  puts "Error: cannot start a bot. A pid.txt file was found. A bot may be already running."
  exit(1)
end
pid = Process.fork do
  #require 'echo_bot'
  #bot = EchoBot.new
  bot = EnWikiBot.new(server, port, channel, password) 
  irc = IRCClient.new(bot, server, port, channel, password)
  trap("QUIT") { irc.close; exit }
  while true do end
end
pid_file = File.open(PID_FILE_PATH, "w")
pid_file.write(pid.to_s)
pid_file.close
Process.detach(pid)
