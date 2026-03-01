module Friday
  class Session < ActiveRecord::Base
    has_many :messages, dependent: :destroy

    def add_message(role, content, tokens = {})
      messages.create!(
        role: role,
        content: content,
        prompt_tokens: tokens[:prompt],
        completion_tokens: tokens[:completion]
      )
      self.total_tokens += (tokens[:prompt] || 0) + (tokens[:completion] || 0)
      save!
    end
  end
end
