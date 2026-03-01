require_relative "../lib/friday"
require "stringio"

# Setup
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)

session = Friday::SessionStore.new("patch_test_session")
agent = Friday::Agent.new(config, session)

# Reset target file
target_path = "test/test_target.rb"
File.write(target_path, <<~RUBY)
def hello
  puts "Hello, World!"
end

def calculate_sum(a, b)
  # This is a comment
  return a + b
end

def goodbye
  puts "Goodbye!"
end
RUBY

# We need to simulate user input for the [Y/n] prompt
module TTY
  class Prompt
    def yes?(message)
      puts "[Auto-Approve] #{message}"
      true
    end
  end
end

puts "Original Content of #{target_path}:"
puts File.read(target_path)
puts "-----------------------------------"

prompt = "Please modify the 'calculate_sum' method in #{target_path} to print 'Calculating...' before the return statement."

puts "Sending instruction to agent..."
response = agent.ask(prompt)
puts "Agent Response: #{response}"

puts "-----------------------------------"
puts "New Content of #{target_path}:"
new_content = File.read(target_path)
puts new_content

if new_content.include?("puts \"Calculating...\"") || new_content.include?("puts 'Calculating...'")
  if new_content.include?("def hello") && new_content.include?("def goodbye")
    puts "\nRESULT: Patching worked perfectly and was surgical!"
  else
    puts "\nRESULT: Patching FAILED (Corrupted other parts of the file)."
  end
else
  puts "\nRESULT: Patching FAILED (Change not applied)."
end
