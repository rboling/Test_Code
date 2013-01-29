class Enrollment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :offering
  has_one :folder
  after_create :update_rankings_add_class
  before_destroy :update_rankings_delete_class
  
  validates_uniqueness_of :offering_id, :scope => [:user_id]
  
  after_create do
    Folder.create(:user => self.user, :enrollment => self, :name => self.offering.course.title)
  end
  
  def update_rankings_add_class
    @offering = Offering.find(self.offering_id)
   # @offering.user_ids.each do |id|
   #   if self.user_id != id
   #     Recommendation.connect_new(self.user_id, id, 2)
   #   end  
   # end 

   # @offering.users.each do |user|
   #   if self.user_id != user.id
   #     Recommendation.connect_new(self.user_id, user.id, 2)
   #   end  
   # end 

  end
  
  
end
