require_relative "../lib/friday"

# Setup project
Friday::Project.setup

# Load config
config = YAML.load_file(File.join(Friday::Project.root, "config.yml"))

# Create session
session = Friday::SessionStore.new("tool_test_session")

# Create agent
agent = Friday::Agent.new(config, session)

# Ask a question that SHOULD trigger a tool call (execute_shell)
begin
  puts "Asking: List the files in the current directory using your tools."
  # Note: Agent#ask handles the fallback logic now, so if it fails, it will log to debug.log
  response = agent.ask("List the files in the current directory using your tools.")
  puts "Response: #{response}"
  
  # Check debug log for tool failure
  log_content = File.read(".friday/debug.log").split("
").last(5).join("
")
  if log_content.include?("Tool calling failed")
    puts "
RESULT: This model does NOT support native tool calling via this endpoint."
  else
    puts "
RESULT: Model seems to support tools (or did not fail immediately)."
  end
rescue => e
  puts "Critical Error: #{e.message}"
end
