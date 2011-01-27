require 'socket'
require 'timeout'

class IRCClient
  
  def initialize(bot, server, port, channel, password)
    @log_file = File.new(IRC_LOG_FILE_PATH, "a")
    
    @socket = TCPSocket.open(server, port)
    
    @bot = bot
    @bot.register Proc.new {|message| say(message) }
    @channel = channel =~ /^#/ ? channel : "#" + channel
    
    if password
      @log_file.puts "#{@bot.name} sent:  PASS ********"
      @log_file.flush
      @socket.puts "PASS #{password}"
      @socket.flush
    end
    
    send "NICK #{@bot.name}"
    send "USER #{@bot.name.downcase} 0 * #{@bot.name}"
    #wait until we get the go-ahead messages
    #while not @socket.closed?
    #  message = @socket.gets
    #  log message if message != nil
    #  break if message =~ /:End of \/MOTD command./
    #end
    
    send "JOIN #{@channel}"
    
    @listening_thread = Thread.new do
      until @socket.closed? do
        message = @socket.readline
        #log message
        if message =~ /^PING :(.*)$/
          log message
          send "PONG #{$1}"
        elsif message =~ /^ERROR :Bad password/
          close
          exit(1)
        elsif message =~ /PRIVMSG #{@channel} :(.*)$/
          done = false
          begin
            @bot.hear $1
            done = true
          rescue Exception
            log message
            log $!.to_s + $@.to_s #This also just logs all the exceptions thrown in dealing with stuff...
          ensure
            log 'ERROR at :' + message unless done
          end
        else
          log message
          #doesn't really matter we still log it, we just don't need to respond to it
        end
      end
      
    end#end listening thread
  end #end initialize
  
  def log message
    @log_file.puts "#{@bot.name} received @ #{Time.now.strftime('%Y%m%d %H:%M.%S')}:  #{message}"
    @log_file.flush
  end
  
  def close
    unless @socket.closed?
      send "QUIT"
      @socket.flush
      @socket.close
      @listening_thread.kill
    end
  end
  
  def send(message)
    @log_file.puts "#{@bot.name} sent @ #{Time.now.strftime('%Y%m%d %H:%M.%S')}:  #{message}"
    @log_file.flush
    @socket.puts message + "\r"
    @socket.flush
  end
  
  def say(message)
    send "PRIVMSG #{@channel} :#{message}"
  end
  
end