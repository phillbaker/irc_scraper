require 'rubygems'
require 'socket'

def send socket, message
  socket.puts message + "\r"
  socket.flush
  send_log message
end

def handle_ping message
  send message
end

def handle_message message
  #log "doing nothing - msg"
end

def handle_other message
  #log "doing nothing - other"
end

def receive_log message
  log "received:  " + message
end

def send_log message
  log "sending:   " + message
end

def log message
  puts message
end

socket = TCPSocket.open('irc.freenode.net', 6667)
channel = '#scrapebot'
name = 'Bot' + (rand*1e6).to_i.to_s

send(socket, "NICK #{name}")
send(socket, "USER #{name.downcase} 0 * #{name}")
send(socket, "JOIN #{channel}")

until socket.closed? do
  message = socket.gets
  receive_log message
  if message =~ /^PING :(.*)$/
    handle_ping "PONG #{$1}"
  elsif message =~ /PRIVMSG #{@channel} :(.*)$/
    handle_message $1
  else
    handle_other message
  end
end

