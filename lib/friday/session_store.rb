require "json"

module Friday
  class SessionStore
    attr_reader :id, :file_path, :data

    def initialize(session_id = nil)
      @id = session_id || "session_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
      @file_path = File.join(Project.root, "history", "#{@id}.json")
      load_data
    end

    def load_data
      if File.exist?(@file_path)
        @data = JSON.parse(File.read(@file_path))
      else
        @data = {
          "id" => @id,
          "created_at" => Time.now,
          "messages" => [],
          "stats" => { "tokens" => 0, "actions" => 0 }
        }
        save
      end
    end

    def add_message(role, content, message_obj = nil)
      @data["messages"] << {
        "role" => role,
        "content" => content,
        "timestamp" => Time.now
      }
      if message_obj && message_obj.respond_to?(:input_tokens)
        @data["stats"]["tokens"] += (message_obj.input_tokens || 0) + (message_obj.output_tokens || 0)
      end
      save
    end

    def save
      File.write(@file_path, JSON.pretty_generate(@data))
    end

    def self.list
      Dir.glob(File.join(Project.root, "history", "*.json")).map do |f|
        File.basename(f, ".json")
      end
    end
  end
end
