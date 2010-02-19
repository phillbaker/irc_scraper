require 'song.rb'

class Songs
  
  DEFAULT_DIR_PATH = "#{File.dirname(__FILE__)}/lyrics"
  
  def initialize(path = nil) 
    @dir = path ? Dir.new(path) : Dir.new(DEFAULT_DIR_PATH)
  end
  
  def list
    filenames.map do |filename|
      file = File.new("#{@dir.path}/#{filename}", "r")
      title = file.readline
      file.close
      title
    end
  end
  
  def song(title)
    path = "#{@dir.path}/#{title.downcase.gsub(/^the +/, "").gsub(/[^\w]/, "")}.txt"
    if File.exist?(path)
      file = File.new(path, "r")
      song = Song.new(file.read)
      file.close
      song
    else
      nil
    end
  end
  
  def random_song
    filenames_array = filenames
    filename = filenames[rand(filenames_array.length)]
    file = File.new("#{@dir.path}/#{filename}", "r")
    song = Song.new(file.read)
    file.close
    song
  end
  
  private
  
  def filenames
    @dir.entries.select { |filename| filename =~ /\.txt$/ }
  end
  
end