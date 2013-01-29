class PermissionSetting < ActiveRecord::Base
  
  attr_accessible :permissions_attributes, :offering_permissions_attributes, :group_permissions_attributes, :note_id, :school_can_view, :school_can_copy, :offering_can_view, :buddies_can_view, :buddies_can_copy
  has_many :permissions
  has_many :offering_permissions
  has_many :group_permissions
  belongs_to :note
  
  accepts_nested_attributes_for :permissions, allow_destroy:true
  accepts_nested_attributes_for :offering_permissions, allow_destroy:true
  accepts_nested_attributes_for :group_permissions, allow_destroy:true
  
  after_create do
    if !self.note.owner.shares_with_everyone?
      self.school_can_view = false
      self.school_can_copy = false
      self.save!
    end
  end
  
end
