class Bot
  
  attr_accessor :name
  
  def initialize name = ''
    @name = name.empty? ? ('Bot' + (rand*1e6).to_i.to_s) : name
  end
  
  def register &say
    @say = say
  end
  
  def say message
    #@say.call(message)
    @say.call message
  end
  
  def hear message
  end
  
end