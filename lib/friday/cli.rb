require "thor"
require "tty-prompt"
require "tty-markdown"
require "tty-spinner"

module Friday
  class Cli < Thor
    desc "start", "Initialize project and start a chat session"
    method_option :session_id, type: :string, aliases: "-s", desc: "Resume a specific session ID"
    def start
      Project.setup
      pastel = Pastel.new
      input_handler = InputHandler.new
      
      session_id = options[:session_id]
      session = SessionStore.new(session_id)
      config = Config.load
      Config.apply(config)
      
      agent = Agent.new(config, session)
      
      # Aesthetic Welcome
      puts pastel.bold.cyan(<<-'BANNER')
        ███████╗██████╗ ██╗██████╗  █████╗ ██╗   ██╗
        ██╔════╝██╔══██╗██║██╔══██╗██╔══██╗╚██╗ ██╔╝
        █████╗  ██████╔╝██║██║  ██║███████║ ╚████╔╝ 
        ██╔══╝  ██╔══██╗██║██║  ██║██╔══██║  ╚██╔╝  
        ██║     ██║  ██║██║██████╔╝██║  ██║   ██║   
        ╚═╝     ╚═╝  ╚═╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   
      BANNER
      puts pastel.dim(" Friday v0.1.0 - Local-First Engineering Orchestrator")
      puts "----------------------------------------------------"
      
      # Detection Logic
      if !options[:session_id]
        if Dir.glob("*.v").any? || Dir.glob("*.sv").any?
          puts pastel.yellow("💡 Detected Hardware project. Try switching: /agent HardwareExpert")
        elsif File.exist?("Gemfile") || File.exist?("Rakefile")
          puts pastel.yellow("💡 Detected Ruby project. Try switching: /agent CodeReviewer")
        end
      end

      puts "Session: #{pastel.bright_white(session.id)}"
      puts "Active Persona: #{pastel.green(agent.current_persona.name)}"
      puts "Type /help for commands, or 'exit' to quit."
      puts "----------------------------------------------------"

      loop do
        prompt_text = pastel.bold.green("#{agent.current_persona.name}> ")
        input = input_handler.read_multiline(prompt_text)
        
        break if input.nil? || ["exit", "quit", "/exit", "/quit"].include?(input.downcase.strip)
        next if input.empty?

        case input.strip
        when "/help"
          puts "/index        - Scan and index all project files for RAG"
          puts "/stats        - Show tokens and usage"
          puts "/agent <name> - Manually switch persona"
          puts "/exit, /quit  - Save and exit"
          puts "exit, quit    - Save and exit"
        when "/index"
          spinner = TTY::Spinner.new("[:spinner] Indexing project files...")
          spinner.auto_spin
          # Simple recursive indexing of current dir
          Dir.glob("**/*").each do |file|
            next if File.directory?(file) || file.include?(".friday") || file.include?("node_modules")
            agent.rag.index_file(file)
          end
          spinner.stop("Done!")
        when "/stats"
          puts "Total Session Tokens: #{session.data['stats']['tokens']}"
          puts "Messages: #{session.data['messages'].size}"
        when /^\/agent (.+)$/
          if agent.switch_persona($1.strip)
            puts "Persona switched to: #{agent.current_persona.name}"
          else
            puts "Error: Persona not found."
          end
        else
          print pastel.dim("thinking...")
          
          # Use streaming
          full_response = ""
          first_chunk = true
          
          agent.ask(input) do |chunk|
            if first_chunk
              print "\r" + " " * 20 + "\r" # Clear the thinking message
              first_chunk = false
            end
            print chunk
            full_response += chunk
            $stdout.flush
          end
          
          puts "\n" # New line after stream ends
        end
      end
      
      puts "\n----------------------------------------------------"
      puts "Session paused. To resume this conversation later, run:"
      puts "./bin/friday start -s #{session.id}"
      puts "----------------------------------------------------"
    end

    desc "list", "List available history sessions"
    def list
      Project.setup
      sessions = SessionStore.list
      if sessions.any?
        puts "Available Sessions:"
        sessions.each { |s| puts "- #{s}" }
      else
        puts "No sessions found."
      end
    end
  end
end
