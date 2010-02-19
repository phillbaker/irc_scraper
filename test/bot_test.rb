require 'test/unit'
require File.dirname(__FILE__) + '/../conf/include'
require 'bot.rb'

class BotTest < Test::Unit::TestCase
  
  TEST_MESSAGE = "Test string to say."
  TEST_ACTION = "does something."
  
  def test_register_say_and_act
    said = nil
    acted = nil
    bot = Bot.new 
    bot.register Proc.new { |message| said = message }, Proc.new { |action| acted = action }
    bot.say(TEST_MESSAGE)
    assert_equal TEST_MESSAGE, said
    bot.act(TEST_ACTION)
    assert_equal TEST_ACTION, acted
  end
  
  def test_implicit_name
    bot = Bot.new
    assert bot.name
  end
  
  TEST_NAME = "TestBot"

  def test_explicit_name
    bot = Bot.new(TEST_NAME)
    assert_equal TEST_NAME, bot.name
  end
  
end