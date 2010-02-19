require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'irc_client.rb'
require 'bot.rb'

IRC_LOG_FILE_PATH = IRC_LOG_DIR_PATH + '/test.log'

class TestBot < Bot
  
  PING = "TestBot(PING)"
  
  attr_accessor :heard
  
  def initialize(name)
    @pinged = false
    super(name)
  end
  
  def ping
    say PING
  end
  
  def hear(message) 
    @pinged = @pinged || message.include?(PING)
  end
  
  def pinged?
    @pinged
  end
  
end

# This unit test requires an IRC server to be running and accessible via the network in order to pass.
class IRCClientTest < Test::Unit::TestCase
  
  CHANNEL = '#test'
  SERVER = 'localhost'
  PORT = 6667
  PASSWORD = 'password'
  
  def test_ping_pong
    File.delete(IRC_LOG_FILE_PATH) if File.exist?(IRC_LOG_FILE_PATH)
    pinger = TestBot.new('Pinger')
    ponger = TestBot.new('Ponger')
    irc1 = IRCClient.new(pinger, CHANNEL, SERVER, PORT, PASSWORD)
    irc2 = IRCClient.new(ponger, CHANNEL, SERVER, PORT, PASSWORD)
    sleep 3
    3.times do
      sleep 3
      pinger.ping
      sleep 2
      assert ponger.pinged?
    end
    irc1.close
    irc2.close
    assert File.exist?(IRC_LOG_FILE_PATH)
  end
  
end