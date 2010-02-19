require 'socket'

class IRCClient
  
  def initialize(bot, channel, server, port = 6667, password = nil)
    @bot = bot
    @bot.register Proc.new { |message| say message }, Proc.new { |action| act action }
    @channel = channel =~ /^#/ ? channel : "#" + channel
    @log_file = File.new(IRC_LOG_FILE_PATH, "a")
    @socket = TCPSocket.open(server, port)
    if password
      @log_file.puts "#{@bot.name} sent:  PASS ********"
      @log_file.flush
      @socket.puts "PASS #{password}"
      @socket.flush
    end
    send "NICK #{@bot.name}"
    send "USER #{@bot.name.downcase} 0 * #{@bot.name}"
    send "JOIN #{@channel}"
    @listening_thread = Thread.new do 
      until @socket.closed? do
        message = @socket.gets
        @log_file.puts "#{@bot.name} received:  #{message}"
        if message =~ /^PING :(.*)$/
          send "PONG #{$1}"
        elsif message =~ /^ERROR :Bad password/
          close
          exit(1)
        elsif message =~ /PRIVMSG #{@channel} :(.*)$/
          @bot.hear $1
        end
      end
    end
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
    @socket.puts message
    @socket.flush
  end
  
  def say(message)
    send "PRIVMSG #{@channel} :#{message}"
  end
  
  def act(action)
    send "PRIVMSG #{@channel} :#{1.chr}ACTION #{action}#{1.chr}"
  end
  
end