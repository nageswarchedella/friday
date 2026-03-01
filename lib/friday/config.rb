require "yaml"

module Friday
  class Config
    def self.load
      config_path = File.join(Project.root, "config.yml")
      return {} unless File.exist?(config_path)
      
      YAML.load_file(config_path)
    end

    def self.apply(config_hash = nil)
      config_hash ||= load
      
      RubyLLM.configure do |llm|
        # Load keys from environment variables (only supported ones)
        llm.gemini_api_key    = ENV["GEMINI_API_KEY"]
        llm.openai_api_key    = ENV["OPENAI_API_KEY"]
        llm.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
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
