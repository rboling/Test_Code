class Answer < ActiveRecord::Base

# after_create :send_notifications
 belongs_to :question
 belongs_to :user
 belongs_to :offering
 belongs_to :group

#  def send_notifications
#    author = self.question.user
#    Notifier.new_answer(self, self.user, author, self.question).deliver if author && author.notify_on_answer? and author != user
#  end



end
