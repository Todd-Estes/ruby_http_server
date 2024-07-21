require "socket"

# run w/ curl http://localhost:4221
server = TCPServer.new("localhost", 4221)

loop do
  client_socket, client_address = server.accept

  request = client_socket.gets
  puts "Received Request: #{request}"

  request_line = request.split(" ")[1]
  puts "Request Line: #{request_line}"

  split_request_line = request_line.split("/")
  puts "Split Request Line: #{split_request_line}"

  if split_request_line.empty?
    response = "HTTP/1.1 200 OK\r\n\r\n"
    puts "OK Response: #{response}"
  elsif split_request_line[1] == "echo" && !split_request_line[2].empty?
    text= split_request_line.last
    response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{text.length}\r\n\r\n#{text}"
    puts response
  else
    response = "HTTP/1.1 404 Not Found\r\n\r\n"
    puts "Bad Response: #{response}"
  end

  client_socket.puts response
  client_socket.close
end