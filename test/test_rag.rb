require_relative "../lib/friday"

# Setup
Friday::Project.setup
rag = Friday::Rag.new

# Index a known file
test_file = "Gemfile"
puts "Indexing #{test_file}..."
rag.index_file(test_file)

# Search
query = "which gems are used?"
puts "Searching for: #{query}"
results = rag.search(query, 2)

if results.any?
  puts "Found #{results.size} results:"
  results.each do |r|
    puts "- Path: #{r[:path]}"
    puts "  Snippet: #{r[:text][0..100]}..."
  end
else
  puts "No results found."
end
