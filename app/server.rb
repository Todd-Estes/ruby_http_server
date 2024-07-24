require "socket"
require "zlib"
require "stringio"
# run this w/ ruby app/server.rb --directory /tmp/
# run w/ curl http://localhost:4221
server = TCPServer.new("localhost", 4221)
server_compression_schemes = ["gzip"]

def supported_client_encoding(server_compression_schemes, client_encoding_string)
  client_encodings = client_encoding_string.split(", ")
  server_compression_schemes.detect { |scheme| client_encodings.include?(scheme) }
end

def gzip(string)
  string_io = StringIO.new
  Zlib::GzipWriter.wrap(string_io) do |gz|
    gz.write(string)
  end
  string_io.string
end

loop do
  Thread.start(server.accept) do |client_socket, client_address| 
    request = client_socket.gets.chomp
    puts "Received Request: #{request}"

    request_method, request_line, _ = request.split(" ")
    puts "Request Method: #{request_method}"
    puts "Request Line: #{request_line}"

    split_request_line = request_line.split("/")
    puts "Split Request Line: #{split_request_line}"

    # create request headers hash
    request_headers = {} 
    while line = client_socket.gets
      break if line == "\r\n"
      header_key, header_value = line.split(": ")
      request_headers[header_key] = header_value.strip
    end    
    puts request_headers

    if request_method == "POST"
      puts request_headers
      body = client_socket.read(request_headers["Content-Length"].to_i)
      puts "Request Body: #{body}"
      file_path =  ARGV[1]
      file_name = split_request_line[2]
      File.open("#{file_path}#{file_name}", "w") do |file|
        file.write(body)
      end
      response = "HTTP/1.1 201 Created\r\n\r\n"
      puts response
    elsif split_request_line.empty?
      response = "HTTP/1.1 200 OK\r\n\r\n"
      puts "OK Response: #{response}"
    elsif split_request_line[1] == "user-agent"
      user_agent_value = request_headers["User-Agent"]
      response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{user_agent_value.length}\r\n\r\n#{user_agent_value}"
      puts "/user-agent endpoint response: #{response}"
    elsif split_request_line[1] == "echo" && !split_request_line[2].empty?
      client_encoding = request_headers["Accept-Encoding"]
      if client_encoding
        supported_client_encoding = supported_client_encoding(server_compression_schemes, client_encoding)
        puts "supported_client_encoding: #{supported_client_encoding}"
        if supported_client_encoding
          compressed_string = gzip(split_request_line.last.strip)
          puts compressed_string
          response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: #{supported_client_encoding}\r\nContent-Length: #{compressed_string.length}\r\n\r\n#{compressed_string}"
          puts response
        else
          response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"
          puts response
        end
      else
        text = split_request_line.last
        response = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{text.length}\r\n\r\n#{text}"
        puts response
      end
    elsif split_request_line[1] == "files"
      puts "ARGV: #{ARGV[1]}"
      file_name = split_request_line[2]
      file_path =  "#{ARGV[1]}"
      puts "FILE NAME: #{file_name}"
      puts "#{file_path}#{file_name}"
      if File.file?("#{file_path}#{file_name}")
        puts "YELLO"
        begin
          file_content = File.read("#{file_path}#{file_name}")
          response = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{file_content.length}\r\n\r\n#{file_content}!"
        rescue
          client_socket.puts "HTTP/1.1 404 Not Found\r\n\r\n"
        end
      else
        puts 'NO FILE'
        response = "HTTP/1.1 404 Not Found\r\n\r\n"
      end
    else
      response = "HTTP/1.1 404 Not Found\r\n\r\n"
      puts "Bad Response: #{response}"
    end

    client_socket.puts response
    client_socket.close
  end
end

