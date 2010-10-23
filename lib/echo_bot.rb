require 'bot.rb'

class EchoBot < Bot
  def hear(message)
    #say message #'helloworld'
    if message =~ /ping/
      say 'pong'
    end
  end
end