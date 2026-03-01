module Friday
  class Skill
    attr_reader :name, :description, :tools, :system_prompt

    def initialize(name:, description:, tools: [], system_prompt: "")
      @name = name
      @description = description
      @tools = tools
      @system_prompt = system_prompt
    end

    class Registry
      @skills = {}

      def self.register(skill_class)
        instance = skill_class.new
        @skills[instance.name.to_sym] = instance
      end

      def self.all
        @skills.values
      end

      def self.find(name)
        @skills[name.to_sym]
      end

      def self.load_from_file(path)
        return false unless File.exist?(path)
        load path
        # The skill file should call Registry.register(SkillClass) at the end
        true
      rescue => e
        warn "Failed to load skill from #{path}: #{e.message}"
        false
      end
    end
  end
end
