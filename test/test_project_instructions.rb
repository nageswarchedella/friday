require_relative "../lib/friday"

# Setup
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)

# Create a temporary FRIDAY.md
File.write("FRIDAY.md", "Project Rule: Always start your response with the word 'PROJECT_READY'.")

begin
  session = Friday::SessionStore.new("project_instr_test")
  agent = Friday::Agent.new(config, session)

  puts "Testing project-specific instructions (FRIDAY.md)..."
  response = agent.ask("Hello, who are you?")
  
  puts "Agent Response: #{response}"

  if response.include?("PROJECT_READY")
    puts "
SUCCESS: Agent followed instructions from FRIDAY.md!"
  else
    puts "
FAILURE: Agent ignored FRIDAY.md instructions."
  end
ensure
  # Clean up
  File.delete("FRIDAY.md") if File.exist?("FRIDAY.md")
end
