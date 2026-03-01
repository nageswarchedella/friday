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
      Dir.glob(File.join(Project.root, "agents", "*.md")).map do |f|
        new(f)
      end
    end

    def self.find_by_name(name)
      all.find { |p| p.name.downcase == name.downcase }
    end
  end
end
