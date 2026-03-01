require_relative "../lib/friday"

# Setup
Friday::Project.setup
config = Friday::Config.load
Friday::Config.apply(config)
rag = Friday::Rag.new

puts "--- CHAOS TEST: RAG STRESS ---"
puts "Config: #{config['provider']} | Embed: #{config['embedding_model']}"
puts "Indexing 100 files in chaos_junk/..."

start_time = Time.now
# We call index_file directly on the junk files
Dir.glob("chaos_junk/*.txt").each do |file|
  # Bypass the internal filter for this test
  content = File.read(file)
  checksum = Digest::SHA256.hexdigest(content)
  
  rag.instance_variable_get(:@db).execute("INSERT INTO file_chunks (path, chunk_text, checksum) VALUES (?, ?, ?)", [file, content, checksum])
  rowid = rag.instance_variable_get(:@db).last_insert_row_id
  embedding = rag.generate_embedding(content)
  
  # Insert into vec table
  begin
    rag.instance_variable_get(:@db).execute("INSERT INTO vec_chunks (rowid, embedding) VALUES (?, ?)", [rowid, embedding.pack("f*")])
  rescue => e
    # Dimensions might have changed
    rag.send(:recreate_vec_table, embedding.size)
    rag.instance_variable_get(:@db).execute("INSERT INTO vec_chunks (rowid, embedding) VALUES (?, ?)", [rowid, embedding.pack("f*")])
  end
  
  print "."
  $stdout.flush
end
puts "\nIndexing complete in #{(Time.now - start_time).round(2)}s"

puts "Testing search speed..."
start_time = Time.now
results = rag.search("Junk content 50", 10)
puts "Search complete in #{(Time.now - start_time).round(2)}s"

if results.any?
  puts "SUCCESS: Found #{results.size} matches."
  puts "First match: #{results.first[:path]}"
else
  puts "FAILURE: No matches found in junk data."
end
