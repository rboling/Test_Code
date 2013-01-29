class PrivacySetting < ActiveRecord::Base
  belongs_to :user
  attr_accessible :notify_on_post_comment, :notify_on_answer,:notify_on_new_post, :notify_on_new_question, 
  :notify_on_new_message, :notify_on_session_invite
end
