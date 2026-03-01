require_relative "../lib/friday"

# Setup project
Friday::Project.setup

# Load config
config = YAML.load_file(File.join(Friday::Project.root, "config.yml"))

# Create session
session = Friday::SessionStore.new("test_session")

# Create agent
agent = Friday::Agent.new(config, session)

# Ask a simple question
begin
  puts "Asking: who are you?"
  response = agent.ask("who are you?")
  puts "Response: #{response}"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(10)
end
