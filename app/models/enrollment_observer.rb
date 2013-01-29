class EnrollmentObserver < ActiveRecord::Observer
  observe :enrollment

  def after_create(enrollment)
    enrollment.user.friends.each do |user|
      begin
        message_body = ActivityRenderer.new.generate_message(user, 'course_add', :offering => enrollment.offering, :user => enrollment.user)
        ActivityMessage.create(:user => user, :body => message_body, :activist => enrollment.user)
      rescue
        nil
      end
    end
  end
end
