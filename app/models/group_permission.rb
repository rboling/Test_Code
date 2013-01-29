class GroupPermission < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :group
  belongs_to :permission_setting
  attr_accessible :can_view, :note_id, :can_edit, :can_copy, :group_id
  validates :group_id, :uniqueness => {:scope => :note_id}
end
