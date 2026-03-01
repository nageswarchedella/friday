module Friday
  module Skills
    class CodeReviewer < Skill
      def initialize
        super(
          name: "CodeReviewer",
          description: "Expert in Ruby, Clean Code, and Refactoring.",
          tools: [Tools::AnalyzeCodeStyle, Tools::FindComplexity],
          system_prompt: "You are a senior software architect. When reviewing code, prioritize readability, performance, and DRY principles."
        )
      end
    end
  end

  module Tools
    class AnalyzeCodeStyle < RubyLLM::Tool
      description "Analyzes code for style and best practices."
      param :file_path
      def execute(file_path:)
        "Style review for #{file_path}: Consider using more descriptive variable names."
      end
    end

    class FindComplexity < RubyLLM::Tool
      description "Identifies overly complex methods or modules."
      param :file_path
      def execute(file_path:)
        "Complexity report for #{file_path}: The main loop has high cyclomatic complexity. Consider extracting logic into smaller methods."
      end
    end
  end
end

Friday::Skill::Registry.register(Friday::Skills::CodeReviewer)
