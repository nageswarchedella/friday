module Friday
  class Message < ActiveRecord::Base
    belongs_to :session
  end
end
