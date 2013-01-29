class OfferingPermission < ActiveRecord::Base
  # attr_accessible :title, :body

  # attr_accessible :title, :body
  belongs_to :offering
  #belongs_to :note
  belongs_to :permission_setting
  
  attr_accessible :can_view, :note_id, :can_edit, :can_copy, :offering_id
  
  validates :offering_id, :uniqueness => {:scope => :note_id}
  
 # after_create do  
 #   unless self.user_id == self.permission_setting.note.user_id
      #uri = URI.parse("http://staging01.c45577.blueboxgrid.com:9292/faye")
      #ri = URI.parse("http://localhost:9292/faye") #change this for staging
 #     uri = URI.parse("http://app01.c45577.blueboxgrid.com:9292/faye")
 #     options = {:note_id => self.permission_setting.note.id, :sender => self.permission_setting.note.owner, :receiver => self.user, :note => self.permission_setting.note}
 #     message = "#{self.permission_setting.note.owner.name} shared a note, \"#{(options[:note]).name}\" with you."
 #     data = {:user_id => self.user.id, :message => message, :intent => "shared_note", :current => true, :args => options}
 #     serialized_data = data.to_json
 #     notification = {:channel => "/broadcasts/user/#{self.user}", :data => serialized_data}
 #     Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)
 #   end
 # end
  
end
