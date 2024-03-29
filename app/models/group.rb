class Group < ActiveRecord::Base

  has_attached_file :avatar, 
    :styles => {:large => "400X400>", :medium => "50x50#", :thumb => "25x25#" }, 
    :default_url => "/assets/generic_avatar_:style.jpg",
    :storage => :s3, 
    :s3_credentials => "#{Rails.root}/config/s3.yml",
    :bucket => "bucket_dev_sh0" # "studyhall#{Rails.env}"

  attr_accessor :delete_avatar
  attr_accessor :update_group_id

  searchable :auto_remove => true do
    text :group_name do
      group_name.downcase
    end
    text :bio
    string :owner_name do
      owner.last_name.downcase
    end
    string :group_name do
      group_name.downcase
    end
    boolean :active
    integer :member_count do
      members.count
    end
  end
  belongs_to :study_session
  has_many :member_requests
  has_many :posts
  belongs_to :notebook
  has_many :group_invites

  has_many :questions
  has_many :answers

  belongs_to :owner, :class_name => "User"


  has_and_belongs_to_many :notes
  has_and_belongs_to_many :members, :join_table => :members_groups, :class_name => "User"
  has_and_belongs_to_many :admins, :join_table => :admins_groups, :class_name => "User"

  validates_attachment_content_type :avatar, :content_type =>  ["image/jpeg", "image/jpg", "image/x-png", "image/pjpeg", "image/png", "image/gif"], :message => "Oops! Make sure you are uploading an image file." 
  validates_attachment_size :avatar, :less_than => 10.megabyte, :message => "Max Size of the image is 10M"

  scope :for_user, lambda {|user| where(:id => (select(:id).where(:user_id => user.id).map(&:id) + user.group_invites.map(&:group_id))) }
  scope :with_users, lambda {|user_ids| where(:id => GroupInvite.where(:user_id => user_ids).select(:group_id).all.map(&:group_id)) }



  def privacy_option
    if self.privacy_open
      :open
    elsif self.privacy_closed
      :closed
    else
      :secret
    end
  end

  def documents(type=nil)
    type ? notes.where("doc_type = ?", type) : self.notes
  end

  def group_posts_with_parent(parent)
    if parent == nil
      GroupPost.where("group_id = ? AND root = ?", self.id, true).order("created_at DESC");
    else
      GroupPost.where("group_id = ? AND comment_id = ?", self.id, parent.id).order("created_at DESC");
    end
  end

  def unanswered_member_requests
    MemberRequest.where("group_id = ? AND answered = ?", self.id, false)
  end

  def admin?(user)
    admins.include?(user)
  end

  def member?(user)
    members.include?(user)
  end

  def avatar_url(size = nil)
    photo_url(size)
  end
  
  def has_avatar?
    self.avatar_file_name
  end

  def photo_url(size = :medium)
    if avatar.file?
      avatar.url(size)
    else
      "/assets/generic_avatar_#{size.to_s}.jpg"
    end
  end

end
