require "tty-prompt"

module Friday
  module Tools
    # ... (Tools remain unchanged)
    class ReadFile < RubyLLM::Tool
      description "Reads an existing file from the local project."
      param :path
      def execute(path:); File.read(path); rescue => e; "Error: #{e.message}"; end
    end

    class CreateFile < RubyLLM::Tool
      description "Creates a BRAND NEW file with full content."
      param :path
      param :content
      def execute(path:, content:)
        prompt = TTY::Prompt.new
        puts "\n[Action] AI wants to CREATE new file: #{path}"
        if prompt.yes?("Allow creation of #{path}?")
          File.write(path, content)
          "Successfully created #{path}."
        else
          "User DENIED creation of #{path}."
        end
      end
    end

    class PatchFile < RubyLLM::Tool
      description "Modifies an existing file using a SEARCH/REPLACE block."
      param :path
      param :search_text
      param :replace_text
      def execute(path:, search_text:, replace_text:)
        prompt = TTY::Prompt.new
        old_content = File.read(path) rescue (return "Error: File #{path} not found.")
        new_content = DiffEngine.apply_patch(old_content, search_text, replace_text)
        return "Error: Could not find exact search_text in #{path}." if new_content.nil?
        
        puts "\n[Action] AI wants to PATCH file: #{path}"
        puts DiffEngine.generate_diff(path, old_content, new_content)
        if prompt.yes?("\nApply these changes to #{path}?")
          File.write(path, new_content)
          "Successfully patched #{path}."
        else
          "User DENIED patch for #{path}."
        end
      end
    end

    class SearchRag < RubyLLM::Tool
      description "Explicitly search the project context for more details."
      param :query
      def execute(query:)
        results = Agent.current_instance.rag.search(query)
        results.any? ? results.map { |r| "[File: #{r[:path]}]\n#{r[:text]}" }.join("\n---\n") : "No results found."
      end
    end

    class UsePersona < RubyLLM::Tool
      description "Switch agent persona."
      param :name
      def execute(name:); Agent.current_instance.switch_persona(name) ? "Switched to #{name}." : "Persona #{name} not found."; end
    end

    class CreatePersona < RubyLLM::Tool
      description "Creates a new sub-agent persona MD file."
      param :name
      param :description
      param :instructions
      def execute(name:, description:, instructions:)
        path = File.join(Project.root, "agents", "#{name.downcase.gsub(' ', '_')}.md")
        File.write(path, "---\nname: #{name}\ndescription: #{description}\n---\n#{instructions}")
        "Created Persona #{name} at #{path}."
      end
    end

    class ExecuteShell < RubyLLM::Tool
      description "Run a terminal command. User will be asked for confirmation."
      param :command
      def execute(command:)
        prompt = TTY::Prompt.new
        puts "\n[Action] AI wants to RUN command: #{command}"
        if prompt.yes?("Execute command?")
          output = `#{command} 2>&1`
          puts "[System] Command finished. Sending output back to AI..."
          "[Command Output]:\n#{output}"
        else
          "User DENIED shell execution."
        end
      end
    end
  end

  class Agent
    attr_reader :session, :config, :current_persona, :rag
    class << self; attr_accessor :current_instance; end

    def initialize(config, session)
      @config = config
      @session = session
      @rag = Rag.new
      @current_persona = PersonaStore.find_by_name("Generalist") || PersonaStore.all.first
      self.class.current_instance = self
      Config.apply(@config)
    end

    def switch_persona(name)
      persona = PersonaStore.find_by_name(name)
      if persona
        @current_persona = persona
        true
      else
        false
      end
    end

    def global_system_prompt
      path = @config["system_prompt_path"] || File.join(Project.root, "system.md")
      global = File.exist?(path) ? File.read(path) : ""
      project_md = File.join(Dir.pwd, "FRIDAY.md")
      project_specific = File.exist?(project_md) ? "\n\n# PROJECT SPECIFIC INSTRUCTIONS:\n#{File.read(project_md)}" : ""
      global + project_specific
    end

    def ask(input, &block)
      Project.debug_log("User Input: #{input}")
      @session.add_message("user", input)
      
      rag_results = @rag.search(input, 3) rescue []
      context_text = rag_results.any? ? rag_results.map { |r| "[File: #{r[:path]}]\n#{r[:text]}" }.join("\n---\n") : "No relevant context."

      system_prompt = <<~PROMPT
        # GLOBAL SYSTEM INSTRUCTIONS:
        #{global_system_prompt}
        # ACTIVE PERSONA ROLE:
        #{@current_persona.instructions}
        # CONTEXT:
        Current directory: #{Dir.pwd}
        Session: #{@session.id}
        # LOCAL PROJECT CONTEXT (RAG):
        #{context_text}
        # AVAILABLE PERSONAS:
        #{PersonaStore.all.map { |p| "- #{p.name}: #{p.frontmatter['description']}" }.join("\n")}
        # FILE MODIFICATION PROTOCOL:
        1. To CREATE a new file, use create_file.
        2. To MODIFY an existing file, use patch_file.
        3. For patch_file, you MUST provide a SEARCH block and a REPLACE block.
      PROMPT

      build_chat = -> {
        provider_symbol = case @config["provider"]
        when "ollama" then :ollama
        when "openai_compatible", "lm_studio", "vllm" then :openai
        when "openai"    then :openai
        when "anthropic" then :anthropic
        when "gemini"    then :gemini
        when "mistral"   then :mistral
        when "groq"      then :groq
        when "deepseek"  then :deepseek
        else (@config["provider"] || :gemini).to_sym
        end

        c = RubyLLM.chat(model: @config["model"], provider: provider_symbol, assume_model_exists: true)
        c.add_message(role: :system, content: system_prompt)
        @session.data["messages"].last(20).each { |m| c.add_message(role: m["role"].to_sym, content: m["content"]) }
        c
      }

      tools = [Tools::ReadFile, Tools::CreateFile, Tools::PatchFile, Tools::SearchRag, Tools::UsePersona, Tools::CreatePersona, Tools::ExecuteShell]
      chat = build_chat.call
      
      # We'll handle tool loops manually to support non-standard models like Minimax
      loop_count = 0
      max_loops = 5
      
      current_input = input
      last_response = nil

      while loop_count < max_loops
        loop_count += 1
        
        begin
          last_response = chat.with_tools(*tools).ask(current_input) do |chunk|
            yield chunk.content if block_given? && chunk.content
          end
        rescue => e
          Project.debug_log("Chat failure: #{e.message}. Attempting chat-only fallback.")
          last_response = build_chat.call.ask(current_input) do |chunk|
            yield chunk.content if block_given? && chunk.content
          end
        end

        # Check for tool calls (standard or manual XML-like format)
        tool_results = []
        
        # 1. Standard RubyLLM/OpenAI tool calls
        if last_response.respond_to?(:tool_calls) && last_response.tool_calls&.any?
          # Handled automatically by ruby_llm if we don't break
          # But we want to ensure history is synced
        end

        # 2. Manual parsing for Minimax/Prompt-based models
        if last_response.content =~ /<invoke name="(.+?)">/m
          # Extract tool name and parameters (Very basic extraction)
          tool_name = $1.split("--").last # e.g. friday--tools--read_file -> read_file
          
          # This is getting complex for a single Turn. 
          # For v0.1.0, let's rely on standard RubyLLM tool loops if possible.
          # If it's failing, it's likely because the model isn't being recognized as tool-capable.
        end

        # Sync and break if no tool calls detected by ruby_llm
        sync_history(chat)
        break # Let ruby_llm handle the internal tool loop for now
      end

      last_response.content
    end

    private

    def sync_history(chat)
      user_index = chat.messages.rindex { |m| m.role == :user }
      return unless user_index
      chat.messages[(user_index + 1)..-1].each do |m|
        content = m.content
        if content.nil? || content.empty?
          if m.respond_to?(:tool_calls) && m.tool_calls&.any?
            content = "[TOOL_CALL] #{m.tool_calls.map(&:name).join(', ')}"
          elsif m.role == :tool
            content = "[TOOL_RESULT]"
          end
        end
        @session.add_message(m.role.to_s, content, m)
      end
    end
  end
end
