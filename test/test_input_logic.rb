require_relative "../lib/friday"
require "reline"

# Setup
Friday::Project.setup
handler = Friday::InputHandler.new

puts "Testing Multiline Input Logic..."

# Use a double backslash to represent a single literal backslash in the simulation
$simulated_input = ["First part \\", "Second part"]

# Monkeypatch Reline.readline for this test
module Reline
  def self.readline(prompt, history)
    val = $simulated_input.shift
    puts "#{prompt}#{val}"
    val
  end
end

full_input = handler.read_multiline("TestPrompt> ")

puts "\nCombined Result:"
p full_input

expected = "First part\nSecond part"
if full_input == expected
  puts "\nSUCCESS: Multiline input logic is working perfectly!"
else
  puts "\nFAILURE: Expected #{expected.inspect}, but got #{full_input.inspect}"
end
