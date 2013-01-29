class FacebookRequest < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :offering
end
