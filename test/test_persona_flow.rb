require_relative "../lib/friday"

# Setup
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)

session = Friday::SessionStore.new("persona_test_session")
agent = Friday::Agent.new(config, session)

puts "Available Personas before test:"
puts Friday::PersonaStore.all.map(&:name).join(", ")
puts "-----------------------------------"

# 1. Create Persona
creation_prompt = "Please create a new persona for me named 'HardwareExpert'. Its description should be 'Expert in SystemVerilog and RTL Design'. Its instructions should be 'You are a specialized hardware architect. Always suggest non-blocking assignments for sequential logic.'"

puts "Sending creation instruction..."
agent.ask(creation_prompt)

# 2. Verify file exists
file_path = ".friday/agents/verilogexpert.md"
if File.exist?(file_path)
  puts "SUCCESS: Persona file created at #{file_path}"
  puts "File Content:"
  puts File.read(file_path)
else
  puts "FAILURE: Persona file NOT found at #{file_path}"
end

puts "-----------------------------------"

# 3. Test Persona Switching
puts "Switching to HardwareExpert..."
if agent.switch_persona("HardwareExpert")
  puts "SUCCESS: Agent successfully switched to HardwareExpert"
  puts "Current Persona Name: #{agent.current_persona.name}"
else
  puts "FAILURE: Agent failed to switch persona."
end
