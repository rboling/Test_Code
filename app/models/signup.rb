class Signup < ActiveRecord::Base
  # attr_accessible :title, :body
  
  acts_as_authentic do |config|
     config.require_password_confirmation = false
     config.perishable_token_valid_for = 2.days
   end
  
  belongs_to :school
  
  validate :email_should_be_present
  validates_uniqueness_of :email, :on => :save
  
  before_save do
    self.school = School.from_email(self.email) if self.email and self.school_id.nil?
  end
  
  after_create do
    if self.school and self.school.active
      #send email here too
    end
  end
  
  def deliver_activation_email
    reset_perishable_token!
    Notifier.activation_email(self).deliver
  end
  
  def email_should_be_present
    self.errors[:email] = "cannot be blank" if (email.blank? && read_attribute(:active) == true)
  end
  
end
