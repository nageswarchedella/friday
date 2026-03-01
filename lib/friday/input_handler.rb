require "reline"
require "fileutils"

module Friday
  class InputHandler
    HISTORY_FILE = File.join(Project.root, "prompt_history.log")

    def initialize
      setup_history
    end

    def setup_history
      if File.exist?(HISTORY_FILE)
        File.readlines(HISTORY_FILE).each { |line| Reline::HISTORY << line.chomp }
      end
    end

    def save_history(line)
      return if line.nil? || line.strip.empty?
      File.open(HISTORY_FILE, "a") { |f| f.puts line }
    end

    def readline(prompt_text)
      line = Reline.readline(prompt_text, true)
      save_history(line)
      line
    end

    def read_multiline(prompt_text)
      buffer = []
      loop do
        current_prompt = buffer.empty? ? prompt_text : "  | "
        line = Reline.readline(current_prompt, true)
        
        break if line.nil? # Ctrl+D
        
        # Check if line ends with a backslash (ignoring trailing spaces)
        trimmed = line.rstrip
        if trimmed.end_with?("\\")
          buffer << trimmed[0...-1].strip # Remove the backslash and any space before it
        else
          buffer << line
          break
        end
      end
      
      full_input = buffer.join("\n").strip
      save_history(full_input) unless full_input.empty?
      full_input
    end
  end
end
