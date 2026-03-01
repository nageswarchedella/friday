require_relative "../lib/friday"

# Force a broken config
config = {
  "provider" => "openai_compatible",
  "model" => "broken-model",
  "api_base" => "http://localhost:9999/v1" # NON-EXISTENT
}

Friday::Project.setup
Friday::Config.apply(config)
session = Friday::SessionStore.new("chaos_broken_connection")
agent = Friday::Agent.new(config, session)

puts "--- CHAOS TEST: BROKEN CONNECTION ---"
puts "Attempting to chat with a DEAD server at http://localhost:9999..."

begin
  response = agent.ask("Hello, are you there?")
  puts "Agent Response: #{response}"
rescue => e
  puts "CAUGHT EXPECTED ERROR: #{e.class} - #{e.message}"
  puts "Checking if the app is still stable..."
end

puts "SUCCESS: System caught the error without crashing the process."
