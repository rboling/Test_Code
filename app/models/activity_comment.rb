class ActivityComment < ActiveRecord::Base
  # attr_accessible :title, :body
 belongs_to :activity_message
 belongs_to :user
end
