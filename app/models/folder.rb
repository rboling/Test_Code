class Folder < ActiveRecord::Base
  attr_accessible :name, :enrollment_id, :user_id, :enrollment, :user
  has_many :notebooks
  has_many :notes
  belongs_to :enrollment
  belongs_to :user
  
  def course_name
    if self.enrollment
      self.enrollment.offering.course.compact_name
    else
      nil
    end
  end
  
end
