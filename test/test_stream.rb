require_relative "../lib/friday"

# Setup project
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)

session = Friday::SessionStore.new("stream_test")
agent = Friday::Agent.new(config, session)

# Ask for a VERY long response to force chunking
prompt = "Write a very long and detailed explanation of how a CPU works, including registers, ALU, and control units. Be as verbose as possible."

puts "Testing Streaming with model: #{config['model']}..."
puts "Prompt: '#{prompt[0..50]}...'"

chunks_received = 0
start_time = Time.now
first_chunk_at = nil

begin
  agent.ask(prompt) do |chunk|
    first_chunk_at ||= Time.now
    chunks_received += 1
    print chunk
    $stdout.flush
  end
  
  end_time = Time.now
  total_duration = end_time - start_time
  stream_duration = first_chunk_at ? (end_time - first_chunk_at) : 0

  puts "\n\n--- STREAMING STATS ---"
  puts "Total chunks received: #{chunks_received}"
  puts "Time to first chunk: #{(first_chunk_at - start_time).round(3)}s"
  puts "Total duration: #{total_duration.round(3)}s"
  
  if chunks_received > 1
    puts "RESULT: Streaming is WORKING (Chunks arrived over #{stream_duration.round(2)}s)"
  else
    puts "RESULT: Streaming is NOT working. Response arrived in 1 block."
  end
rescue => e
  puts "\nError during stream test: #{e.message}"
end
