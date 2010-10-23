require 'socket'
require 'timeout'

class IRCClient
  
  def initialize(bot, server, port, channel, password)
    @log_file = File.new(IRC_LOG_FILE_PATH, "a")
    
    @socket = TCPSocket.open(server, port)
    
    @bot = bot
    @bot.register Proc.new { |message| say(message) }
    @channel = channel =~ /^#/ ? channel : "#" + channel
    
    if password
      @log_file.puts "#{@bot.name} sent:  PASS ********"
      @log_file.flush
      @socket.puts "PASS #{password}"
      @socket.flush
    end
    
    send "NICK #{@bot.name}"
    send "USER #{@bot.name.downcase} 0 * #{@bot.name}"
    #@socket.puts ""
    #@socket.flush
    while not @socket.closed?
      message = @socket.gets
      log message if message != nil
      break if message =~ /:End of \/MOTD command./
    end
    
    #send "PING :message"
    send "JOIN #{@channel}"
    #@socket.puts ""
    #@socket.flush
    #send ""
    #require 'ruby-debug'; debugger
    #while not @socket.closed?
    #  message = ''
    #  begin 
    #    timeout(3) do
    #      @socket.puts ""
    #      @socket.flush
    #      message = @socket.gets
    #      log message if message != nil
    #    end
    #  rescue Timeout::Error
    #    send "TIME"
    #    break
    #  end
    #  break if message =~ /JOIN :#{@channel}/
      #sleep 1
      #send "TIME"#"VERSION"
    #end
    #send "JOIN #{@channel}"
    #log "got here"
    #send "JOIN #{@channel}"
    #sleep 5
    #@bot.say 'helloworld' #"TIME", false
    
    @listening_thread = Thread.new do 
      until @socket.closed? do
        message = @socket.readline #(nil)
        log message
        if message =~ /^PING :(.*)$/
          send "PONG #{$1}"
        elsif message =~ /^ERROR :Bad password/
          close
          exit(1)
        elsif message =~ /PRIVMSG #{@channel} :(.*)$/
          @bot.hear $1
        else
          #doesn't really matter we still log it, we just don't need to respond to it
          #log "fell through"
        end
      end
    end
  end
  
  def log message
    @log_file.puts "#{@bot.name} received:  #{message}"
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
    @log_file.puts "#{@bot.name} sent:  #{message}"
    @log_file.flush
    @socket.puts message + "\r"
    @socket.flush
  end
  
  def say(message)
    send "PRIVMSG #{@channel} :#{message}"
  end
  
end