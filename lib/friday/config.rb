require "yaml"

module Friday
  class Config
    DEFAULTS = {
      "provider" => "gemini",
      "model" => "gemini-2.5-flash",
      "embedding_model" => "gemini-embedding-001",
      "agentic_mode" => true
    }

    def self.load
      # 1. Defaults
      config = DEFAULTS.dup

      # 2. Global Config (~/.friday/config.yml)
      global_path = File.join(Project.global_root, "config.yml")
      if File.exist?(global_path)
        config.merge!(YAML.load_file(global_path) || {})
      end

      # 3. Local Project Config (./.friday/config.yml)
      local_path = File.join(Project.root, "config.yml")
      if File.exist?(local_path)
        config.merge!(YAML.load_file(local_path) || {})
      end

      # 4. API Key Handling (Environment Variables override everything)
      config["api_key"] = ENV["GEMINI_API_KEY"] if ENV["GEMINI_API_KEY"]
      config["api_key"] = ENV["OPENAI_API_KEY"] if ENV["OPENAI_API_KEY"]
      config["api_key"] = ENV["ANTHROPIC_API_KEY"] if ENV["ANTHROPIC_API_KEY"]
      
      config
    end

    def self.apply(config_hash = nil)
      config_hash ||= load
      
      RubyLLM.configure do |llm|
        # Common keys from environment variables
        llm.gemini_api_key    = config_hash["api_key"] || ENV["GEMINI_API_KEY"]
        llm.openai_api_key    = config_hash["api_key"] || ENV["OPENAI_API_KEY"]
        llm.anthropic_api_key = config_hash["api_key"] || ENV["ANTHROPIC_API_KEY"]
        llm.mistral_api_key   = ENV["MISTRAL_API_KEY"]
        llm.deepseek_api_key  = ENV["DEEPSEEK_API_KEY"]
        
        # Local or Custom Overrides
        case config_hash["provider"]
        when "ollama"
          llm.ollama_api_base = config_hash["api_base"] || "http://localhost:11434/v1"
        when "openai_compatible", "lm_studio", "vllm"
          llm.openai_api_base = config_hash["api_base"]
          llm.openai_api_key = config_hash["api_key"] || ENV["OPENAI_API_KEY"] || "not-needed"
        end
      end
    end
  end
end
