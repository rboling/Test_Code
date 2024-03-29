class Contact < ActiveRecord::Base
  
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :message
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i , :on => :create, :message => "is invalid"
end
