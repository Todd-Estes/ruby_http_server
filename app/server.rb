require "socket"

# run w/ curl http://localhost:4221
server = TCPServer.new("localhost", 4221)

loop do
  client_socket, client_address = server.accept

  request = client_socket.gets
  puts "Received Request: #{request}"

  request_line = request.split(" ")[1]
  puts "Request Line: #{request_line}"

  if request_line == "/"
    response = "HTTP/1.1 200 OK\r\n\r\n"
    puts "OK Response: #{response}"
  else 
    response = "HTTP/1.1 404 Not Found\r\n\r\n"
    puts "Bad Response: #{response}"
  end

  client_socket.puts response
  client_socket.close
end