require "net/http"
require "json"
require "uri"

uri = URI.parse("http://localhost:11434/api/generate")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request.body = JSON.dump({
  model: "gemma3:1b",
  prompt: "Tell me a short story about a cat.",
  stream: true
})

puts "Testing raw Ollama streaming..."
chunks = 0
start_time = Time.now

Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request) do |response|
    response.read_body do |chunk|
      chunks += 1
      print "."
      $stdout.flush
    end
  end
end

puts "
Chunks received: #{chunks}"
puts "Total time: #{Time.now - start_time}s"
