class GroupInvite < ActiveRecord::Base

  belongs_to :group
  belongs_to :user

  after_create :send_message

  attr_accessor :message, :sender_id, :send_email

  def send_message
    return true unless message.present? && sender_id.present?
    sender = User.find(sender_id)
    subject = "#{user.first_name.titleize}, you have been invited to a group!"
    #Notifier.group_invite(sender, user, self).deliver if send_email and user.notify_on_invite?
    sender.send_message?(subject, message, user)
  end



end
