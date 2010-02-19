require 'bot.rb'
require 'songs.rb'

class JoCoBot < Bot
  
  attr_accessor :songs
  
  def initialize(name = BOT_NAME)
    @songs = Songs.new
    @song = nil
    @singing_thread = nil
    super(name)
  end
  
  def hear(message)
    check_if_should_reply message
  end
  
  def check_if_should_reply(message)
    if message =~ /[\s,:.!]#{@name}[\s,:.!]/i || message =~ /^#{@name}[\s,:.!]/i || message =~ /[\s,:.!]#{@name}$/i
      check_for_command message.gsub(/#{@name.downcase}/i, " ")
    elsif message =~ /#{MONKEY_WORD}/i
      monkey
      stop_singing
    end
  end
  
  def check_for_command(message)
    if message =~ /stop/i
      stop_singing
    elsif message =~ /(start|resume)\s+singing/i
      start_singing
    elsif message =~ /sing ["']?(\w.*)/i
      requested_singing($1)
    elsif message =~ /sing/i
      random_singing
    elsif message =~ /song.*called/i || message =~ /name.*song/i
      name_of_song
    end
  end
  
  def requested_singing(title)
    unless singing?
      song = @songs.song title
      if song.nil?
        say UNKNOWN_SONG_RESPONSE
      else
        @song = song
        start_singing
      end
    end
  end
  
  def random_singing
    unless singing?
      @song = nil
      start_singing
    end
  end
  
  def start_singing
    unless singing?
      act STARTING_ACTION
      if @song.nil? || !@song.has_more_lines?
        @song = @songs.random_song
        @song.random_verse
      end
      @singing_thread = Thread.new do
        while @song.has_more_lines? 
          say @song.next_line
          sleep 3
        end
        stop_singing
      end
    end
  end
  
  def stop_singing
    if singing?
      act STOPPING_ACTION
      @singing_thread.kill
    end
  end
  
  def monkey
    act "#{MONKEY_ACTIONS[rand(MONKEY_ACTIONS.length)]}"
  end
  
  def name_of_song
    unless singing?
      if @song.nil?
        say NO_NAME_OF_SONG_RESPONSE
      else
        say "#{NAME_OF_SONG_RESPONSE} \"#{@song.title}.\""
      end
    end
  end
  
  def singing?
    @singing_thread && @singing_thread.alive?
  end
  
end
  