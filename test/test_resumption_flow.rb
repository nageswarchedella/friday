require_relative "../lib/friday"

# Setup
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)

session_id = "resumption_test_#{Time.now.to_i}"

# Turn 1: Establish a memory
puts "--- SESSION START (Turn 1) ---"
session1 = Friday::SessionStore.new(session_id)
agent1 = Friday::Agent.new(config, session1)

puts "Telling the agent a secret fact..."
agent1.ask("My favorite programming language is Ruby and my favorite color is Magenta. Please remember this.")
puts "Session 1 closed."

# Turn 2: Resume and verify memory
puts "
--- SESSION RESUME (Turn 2) ---"
# We re-initialize everything to simulate a fresh start of the app
session2 = Friday::SessionStore.new(session_id)
agent2 = Friday::Agent.new(config, session2)

puts "Asking the agent to recall the fact..."
response = agent2.ask("Based on our previous conversation, what is my favorite language and color?")

puts "Agent Recall: #{response}"

if response.downcase.include?("ruby") && response.downcase.include?("magenta")
  puts "
SUCCESS: Session resumption and context memory are working perfectly!"
else
  puts "
FAILURE: Agent did not remember the context from the previous run."
end
