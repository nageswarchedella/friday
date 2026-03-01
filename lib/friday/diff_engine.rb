require "diff/lcs"
require "pastel"

module Friday
  class DiffEngine
    def self.generate_diff(path, old_content, new_content)
      pastel = Pastel.new
      diffs = Diff::LCS.diff(old_content.split("
"), new_content.split("
"))
      
      output = []
      output << pastel.bold.blue("--- #{path} (Current)")
      output << pastel.bold.blue("+++ #{path} (Proposed)")
      
      # Minimal chunk-based diff for the terminal
      old_lines = old_content.split("
")
      new_lines = new_content.split("
")
      
      Diff::LCS.sdiff(old_lines, new_lines).each do |change|
        case change.action
        when "="
          output << "  #{change.old_element}"
        when "-"
          output << pastel.red("- #{change.old_element}")
        when "+"
          output << pastel.green("+ #{change.new_element}")
        when "!"
          output << pastel.red("- #{change.old_element}")
          output << pastel.green("+ #{change.new_element}")
        end
      end
      
      output.join("
")
    end

    # Apply search/replace blocks (Simplest robust way for LLMs)
    def self.apply_patch(content, search, replace)
      if content.include?(search)
        content.gsub(search, replace)
      else
        nil # Search block not found exactly
      end
    end
  end
end
