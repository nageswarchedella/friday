require "sqlite3"
require "sqlite_vec"
require "digest"
require "pdf-reader"

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
      
      begin
        @db.execute("CREATE VIRTUAL TABLE vec_chunks USING vec0(embedding float[768])")
      rescue SQLite3::SQLException => e
        raise e unless e.message.include?("already exists")
      end
    end

    def generate_embedding(text)
      provider_symbol = case @config["provider"]
      when "ollama" then :ollama
      when "openai_compatible", "lm_studio", "vllm" then :openai
      when "openai"    then :openai
      when "anthropic" then :anthropic
      when "gemini"    then :gemini
      when "mistral"   then :mistral
      when "groq"      then :groq
      when "deepseek"  then :deepseek
      else :gemini
      end

      response = RubyLLM.embed(text, 
        model: @config["embedding_model"] || @config["model"], 
        provider: provider_symbol,
        assume_model_exists: true
      )
      response.vectors
    end

    def extract_text(path)
      return nil unless File.file?(path)
      case File.extname(path).downcase
      when ".pdf"
        reader = PDF::Reader.new(path)
        reader.pages.map(&:text).join("\n")
      else
        File.read(path)
      end
    rescue => e
      Project.debug_log("Failed to extract text from #{path}: #{e.message}")
      nil
    end

    def chunk_text(text, max_size = 1500)
      # Try to split by double newlines (paragraphs/sections) first
      sections = text.split(/\n\n+/)
      chunks = []
      current_chunk = ""

      sections.each do |section|
        if (current_chunk + section).length > max_size
          chunks << current_chunk.strip unless current_chunk.empty?
          current_chunk = section
          
          # If a single section is too big, hard split it
          while current_chunk.length > max_size
            chunks << current_chunk[0...max_size].strip
            current_chunk = current_chunk[max_size..-1]
          end
        else
          current_chunk += "\n\n" + section
        end
      end
      chunks << current_chunk.strip unless current_chunk.empty?
      chunks
    end

    def index_file(path)
      return if !File.file?(path) || path.include?(".friday") || path.include?("node_modules")
      
      content = extract_text(path)
      return if content.nil? || content.empty?
      
      checksum = Digest::SHA256.hexdigest(content)
      existing = @db.get_first_value("SELECT checksum FROM file_chunks WHERE path = ?", [path])
      return if existing == checksum

      old_ids = @db.execute("SELECT id FROM file_chunks WHERE path = ?", [path]).flatten
      if old_ids.any?
        @db.execute("DELETE FROM file_chunks WHERE path = ?", [path])
        @db.execute("DELETE FROM vec_chunks WHERE rowid IN (#{old_ids.join(',')})")
      end

      chunks = chunk_text(content)
      chunks.each do |chunk|
        @db.execute("INSERT INTO file_chunks (path, chunk_text, checksum) VALUES (?, ?, ?)", [path, chunk, checksum])
        rowid = @db.last_insert_row_id
        embedding = generate_embedding(chunk)
        
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
