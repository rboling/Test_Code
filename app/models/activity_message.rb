class ActivityMessage < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :has_likes
  belongs_to :activist, :class_name => "User", :foreign_key => "activist_id"
  has_many :activity_comments
end
