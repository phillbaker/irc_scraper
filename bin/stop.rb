#!/usr/bin/env ruby
# == Synopsis
#
# stop.rb: Stops a currently running JoCoBot
#
# == Usage
#
# ruby stop.rb [OPTIONS]
#
# -h, --help:
#    show help
#

require File.dirname(__FILE__) + '/../conf/include'
require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(['--help', '-h', GetoptLong::NO_ARGUMENT])
opts.each do |opt, arg|
  if opt == '--help'
    RDoc::usage
    exit(0)
  end
end
unless File.exist?(PID_FILE_PATH)
  puts "Error: cannot stop the bot. No pid file exists. A bot may not have been started."
  exit(1)
else
  pid_file = File.new(PID_FILE_PATH, "r")
  pid = pid_file.readline.to_i
  Process.kill("QUIT", pid)
  pid_file.close
  File.delete(PID_FILE_PATH)
end