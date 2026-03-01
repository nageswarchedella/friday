require "fileutils"
require "yaml"

module Friday
  class Project
    ROOT_DIR = ".friday"
    
    def self.setup
      FileUtils.mkdir_p(File.join(ROOT_DIR, "agents"))
      FileUtils.mkdir_p(File.join(ROOT_DIR, "history"))
      
      # Initialize basic config
      config_path = File.join(ROOT_DIR, "config.yml")
      unless File.exist?(config_path)
        File.write(config_path, {
          "provider" => "gemini",      # gemini, ollama, or openai_compatible
          "model" => "gemini-1.5-pro", # the model name to use
          "api_base" => nil,           # e.g., http://localhost:11434/v1 or http://localhost:1234/v1
          "api_key" => nil,            # if the local server requires one
          "system_prompt_path" => nil, 
          "agentic_mode" => false
        }.to_yaml)
      end

      # Initialize default global system prompt
      system_path = File.join(ROOT_DIR, "system.md")
      unless File.exist?(system_path)
        File.write(system_path, <<~MD)
          You are a professional engineering assistant. 
          Your goals are accuracy, safety, and high-quality code.
          Always verify assumptions by reading files before proposing changes.
        MD
      end

      # Create default generalist agent
      default_agent = File.join(ROOT_DIR, "agents", "generalist.md")
      unless File.exist?(default_agent)
        File.write(default_agent, <<~MD)
          ---
          name: Generalist
          description: A highly capable engineering assistant for any industry.
          ---
          You are the lead orchestrator for this engineering project. 
          Your goal is to help the team solve complex problems across hardware and software.
        MD
      end
    end

    def self.root; ROOT_DIR; end
    def self.db_path; File.join(ROOT_DIR, "rag.sqlite3"); end
    def self.debug_log(message)
      File.open(File.join(ROOT_DIR, "debug.log"), "a") { |f| f.puts "[#{Time.now}] #{message}" }
    end
  end
end
