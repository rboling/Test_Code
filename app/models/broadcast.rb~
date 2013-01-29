class Broadcast < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  serialize :args, Hash

  scope :recent, :limit => 5, :order => 'updated_at DESC'

  def link
    case self.intent.to_sym
    when :studyhall_created
      link = study_sessions_path(:clear_broadcasts => true)
    when :message_sent
      link = mailbox_path(:mailbox => "inbox", :clear_broadcasts => true)
    when :class_post
      link = class_path(:id => self.args[:course_id])
    when :question_asked
      link = class_path(:id => self.args[:offering_id])
    when :friend_request
      link = user_path(:id => self.args[:inviter_id])
    when :friend_accept
      link = user_path(:id => self.args[:invitee1_id])
    when :shared_note
      link = note_path(:id => self.args[:note_id])
    when :request_access
      link = note_path(:id => self.args[:note_id])
    end
  end

end
