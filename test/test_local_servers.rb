require_relative "../lib/friday"

def run_test(name, config_hash)
  puts "\n=== Testing #{name} ==="
  Friday::Config.apply(config_hash)
  session = Friday::SessionStore.new("test_#{name.downcase}")
  agent = Friday::Agent.new(config_hash, session)
  
  print "Asking #{config_hash['model']}... "
  response = agent.ask("Hello, what is your name and are you ready to help with engineering?")
  puts "\nResponse: #{response[0..100]}..."
  puts "SUCCESS: #{name} is working!"
rescue => e
  puts "\nFAILURE: #{name} failed: #{e.message}"
  puts e.backtrace.first(5)
end

# 1. Test LM Studio with Qwen
run_test("LM Studio", {
  "provider" => "openai_compatible",
  "model" => "qwen2.5-0.5b-instruct",
  "api_base" => "http://localhost:1234/v1"
})

# 2. Test Ollama
run_test("Ollama", {
  "provider" => "ollama",
  "model" => "minimax-m2.5:cloud",
  "api_base" => "http://localhost:11434/v1"
})
