require "socket"

# run w/ curl http://localhost:4221
server = TCPServer.new("localhost", 4221)

loop do
  Thread.start(server.accept) do |client_socket, client_address| 
    request = client_socket.gets.chomp
    puts "Received Request: #{request}"

    request_line = request.split(" ")[1]
    puts "Request Line: #{request_line}"

    split_request_line = request_line.split("/")
    puts "Split Request Line: #{split_request_line}"

    while line = client_socket.gets
      break if line == "\r\n"
      if line.start_with?("User-Agent")
        user_agent_value = line.split(" ").last
      end
    end    


    if split_request_line.empty?
      response = "HTTP/1.1 200 OK\r\n\r\n"
      puts "OK Response: #{response}"
    elsif split_request_line[1] == "user-agent"
      response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{user_agent_value.length}\r\n\r\n#{user_agent_value}"
      puts "/user-agent endpoint response: #{response}"
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
end

