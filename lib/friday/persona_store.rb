require "yaml"

module Friday
  class PersonaStore
    attr_reader :frontmatter, :instructions, :name

    def initialize(file_path)
      content = File.read(file_path)
      if content =~ /^(---\s*
.*?
?)^(---\s*$
?)/m
        @frontmatter = YAML.safe_load($1)
        @instructions = content.sub($&, "")
        @name = @frontmatter["name"]
      else
        @frontmatter = {}
        @instructions = content
        @name = File.basename(file_path, ".md").capitalize
      end
    end

    def self.all
      # 1. Global Agents
      global_agents = Dir.glob(File.join(Project.global_root, "agents", "*.md")).map { |f| new(f) }
      
      # 2. Local Project Agents
      local_agents = Dir.glob(File.join(Project.root, "agents", "*.md")).map { |f| new(f) }
      
      # Merge: Local agents overwrite global ones with same name
      (global_agents + local_agents).each_with_object({}) do |persona, hash|
        hash[persona.name.downcase] = persona
      end.values
    end

    def self.find_by_name(name)
      all.find { |p| p.name.downcase == name.downcase }
    end
  end
end
