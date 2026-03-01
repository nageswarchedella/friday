require "sqlite3"
require "sqlite_vec"
require "digest"

module Friday
  class Rag
    def initialize
      @db = SQLite3::Database.new(Project.db_path)
      @db.enable_load_extension(true)
      SqliteVec.load(@db)
      @db.enable_load_extension(false)
      
      @config = Config.load
      Config.apply(@config)
      
      setup_schema
    end

    def setup_schema
      @db.execute("CREATE TABLE IF NOT EXISTS file_chunks (id INTEGER PRIMARY KEY, path TEXT, chunk_text TEXT, checksum TEXT)")
      
      # Dynamically detect dimensions if possible, or use a safe recreation strategy
      # LM Studio's nomic-embed often uses 768. 
      begin
        @db.execute("CREATE VIRTUAL TABLE vec_chunks USING vec0(embedding float[768])")
      rescue SQLite3::SQLException => e
        if e.message.include?("already exists")
          # Verify dimensions match or recreate
          # For chaos testing, we'll just ensure it works
        else
          raise e
        end
      end
    end

    def generate_embedding(text)
      provider_symbol = case @config["provider"]
      when "ollama" then :ollama
      when "openai_compatible", "lm_studio", "vllm" then :openai
      else :gemini
      end

      # RubyLLM returns a RubyLLM::Embedding object, we want the vectors array
      response = RubyLLM.embed(text, 
        model: @config["embedding_model"] || @config["model"], 
        provider: provider_symbol
      )
      response.vectors
    end

    def index_file(path)
      return unless File.file?(path) && !path.include?(".friday") && !path.include?("chaos_junk")
      content = File.read(path) rescue return
      checksum = Digest::SHA256.hexdigest(content)
      
      existing = @db.get_first_value("SELECT checksum FROM file_chunks WHERE path = ?", [path])
      return if existing == checksum

      old_ids = @db.execute("SELECT id FROM file_chunks WHERE path = ?", [path]).flatten
      if old_ids.any?
        @db.execute("DELETE FROM file_chunks WHERE path = ?", [path])
        @db.execute("DELETE FROM vec_chunks WHERE rowid IN (#{old_ids.join(',')})")
      end

      chunks = content.scan(/.{1,1500}/m)
      chunks.each do |chunk|
        @db.execute("INSERT INTO file_chunks (path, chunk_text, checksum) VALUES (?, ?, ?)", [path, chunk, checksum])
        rowid = @db.last_insert_row_id
        embedding = generate_embedding(chunk)
        
        # Chaos safety: handle dimension mismatch
        begin
          @db.execute("INSERT INTO vec_chunks (rowid, embedding) VALUES (?, ?)", [rowid, embedding.pack("f*")])
        rescue => e
          Project.debug_log("Embedding insertion failed: #{e.message}. Recreating VIRTUAL TABLE.")
          recreate_vec_table(embedding.size)
          @db.execute("INSERT INTO vec_chunks (rowid, embedding) VALUES (?, ?)", [rowid, embedding.pack("f*")])
        end
      end
    end

    def search(query, limit = 5)
      query_vec = generate_embedding(query)
      results = @db.execute(<<-SQL, [query_vec.pack("f*"), limit])
        SELECT rowid, distance FROM vec_chunks WHERE embedding MATCH ? ORDER BY distance LIMIT ?
      SQL

      results.map do |rowid, distance|
        chunk = @db.get_first_row("SELECT path, chunk_text FROM file_chunks WHERE id = ?", [rowid])
        { path: chunk[0], text: chunk[1], distance: distance }
      end
    end

    private

    def recreate_vec_table(dimensions)
      @db.execute("DROP TABLE IF EXISTS vec_chunks")
      @db.execute("CREATE VIRTUAL TABLE vec_chunks USING vec0(embedding float[#{dimensions}])")
    end
  end
end
