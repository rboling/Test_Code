class Posting < ActiveRecord::Base
  belongs_to :question
  belongs_to :user
  belongs_to :offering
  belongs_to :group

end
