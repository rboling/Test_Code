class Authentication < ActiveRecord::Base
  belongs_to :user

  validates :user, :presence => true #this is a difference between the two
  validates :provider, :presence => true
  validates :uid, :presence => true, :uniqueness => { :scope => [:user_id, :provider] }
end
