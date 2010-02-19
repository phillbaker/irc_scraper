class Bot
  
  attr_accessor :name
  
  def initialize(name = "Bot")
    @name = name
  end
  
  def register(say, act)
    @say = say
    @act = act
  end
  
  def say(message)
    @say.call(message)
  end
  
  def act(action)
    @act.call(action)
  end
  
  def hear(message)
  end
  
end