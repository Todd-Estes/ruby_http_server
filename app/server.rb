require "socket"

# run w/ curl http://localhost:4221
server = TCPServer.new("localhost", 4221)

loop do
  client_socket, client_address = server.accept

  request = client_socket.gets
  puts "Received Request: #{request}"

  response = "HTTP/1.1 200 OK\r\n\r\n"
  puts "Response: #{response}"

  client_socket.puts response
  client_socket.close
end