module Friday
  class SubAgent < ActiveRecord::Base
    # Store tools as a comma-separated string for simplicity
    def tools
      tool_names.to_s.split(",").map(&:strip).reject(&:empty?)
    end

    def self.find_by_name(name)
      find_by("LOWER(name) = ?", name.downcase)
    end
  end
end
