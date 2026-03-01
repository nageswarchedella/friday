require_relative "../lib/friday"

# Setup
Friday::Project.setup
handler = Friday::InputHandler.new

puts "--- CHAOS TEST: INPUT FLOOD ---"
garbage = "X" * 10000
puts "Feeding 10,000 character garbage block into InputHandler logic..."

# Simulate Reline
module Reline
  def self.readline(p, h); $garbage_block; end
end
$garbage_block = garbage

begin
  # Use simple readline to see if it handles the buffer
  result = handler.readline("Chaos> ")
  if result.size == 10000
    puts "SUCCESS: InputHandler handled 10,000 character flood perfectly."
  else
    puts "FAILURE: Input size mismatch."
  end
rescue => e
  puts "FAILURE: Input flood caused crash: #{e.message}"
end
