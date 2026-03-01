require "fileutils"
require "yaml"

module Friday
  class Project
    DEFAULT_ROOT = ".friday"
    GLOBAL_ROOT = File.expand_path("~/.friday")
    
    def self.root
      @root ||= find_root || DEFAULT_ROOT
    end

    def self.global_root; GLOBAL_ROOT; end

    def self.find_root
      current = Dir.pwd
      loop do
        potential = File.join(current, DEFAULT_ROOT)
        return potential if Dir.exist?(potential)
        
        parent = File.expand_path("..", current)
        break if parent == current
        current = parent
      end
      nil
    end
    
    def self.setup_global
      FileUtils.mkdir_p(File.join(global_root, "agents"))
      FileUtils.mkdir_p(File.join(global_root, "history"))
      
      config_path = File.join(global_root, "config.yml")
      unless File.exist?(config_path)
        File.write(config_path, {
          "provider" => "gemini",
          "model" => "gemini-2.5-flash",
          "api_base" => nil,
          "api_key" => nil
        }.to_yaml)
      end
    end
    
    def self.setup(target_dir = nil)
      setup_global

      # If run from start, find or create local root
      target_root = target_dir || find_root || DEFAULT_ROOT
      @root = target_root

      FileUtils.mkdir_p(File.join(target_root, "agents"))
      FileUtils.mkdir_p(File.join(target_root, "history"))
      
      # Initialize basic local config if it doesn't exist
      config_path = File.join(target_root, "config.yml")
      unless File.exist?(config_path)
        # Inherit from global or use defaults
        global_config = YAML.load_file(File.join(global_root, "config.yml")) rescue {}
        File.write(config_path, {
          "provider" => global_config["provider"] || "gemini",
          "model" => global_config["model"] || "gemini-2.5-flash",
          "agentic_mode" => true
        }.to_yaml)
      end

      # Initialize default global system prompt
      system_path = File.join(target_root, "system.md")
      unless File.exist?(system_path)
        File.write(system_path, <<~MD)
          You are a professional engineering assistant. 
          Your goals are accuracy, safety, and high-quality code.
          Always verify assumptions by reading files before proposing changes.
        MD
      end

      # Create default generalist agent
      default_agent = File.join(target_root, "agents", "generalist.md")
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

    def self.db_path; File.join(root, "rag.sqlite3"); end
    def self.debug_log(message)
      FileUtils.mkdir_p(root) # Ensure dir exists for log
      File.open(File.join(root, "debug.log"), "a") { |f| f.puts "[#{Time.now}] #{message}" }
    end
  end
end
