class Song
  
  attr_reader :title
  attr_reader :lyrics
  
  def initialize(string)
    tokens = string.split(/\n\s*\n/)
    title = tokens.delete_at(0)
    @title = title
    @lyrics = tokens.map { |verse| verse.split("\n") }
    beginning
  end
  
  def next_line
    if @current_verse == @lyrics.length
      nil
    else
      line = lyrics[@current_verse][@current_line]
      if @current_line + 1 < @lyrics[@current_verse].length
        @current_line = @current_line + 1
      else
        @current_line = 0
        @current_verse = @current_verse + 1
      end
      line
    end
  end
  
  def random_verse
    @current_line = 0
    @current_verse = rand(@lyrics.length)
  end
  
  def random_line
    @current_verse = rand(@lyrics.length)
    @current_line = rand(@lyrics[@current_verse].length)
  end
  
  def beginning
    @current_verse = 0
    @current_line = 0
  end
  
  def has_more_lines?
    @current_verse < @lyrics.length
  end
  
end