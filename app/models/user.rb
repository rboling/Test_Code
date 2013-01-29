class User < ActiveRecord::Base
  include Amistad::FriendModel


  acts_as_authentic do |config|
    config.require_password_confirmation = false
    config.perishable_token_valid_for = 2.days
  end
  acts_as_voter
  acts_as_voteable
  has_mailbox

  has_attached_file :avatar, 
    :styles => {:large => "400X400>", :medium => "50x50#", :thumb => "25x25#" }, 
    :default_url => "/assets/generic_avatar_:style.png",
    :storage => :s3, 
    :s3_credentials => "#{Rails.root}/config/s3.yml",
    :s3_protocol => 'https',
    :bucket => "bucket_dev_sh0" # "studyhall#{Rails.env}"

  attr_accessor :delete_avatar, :recommendation
  before_post_process :paperclip_hack_filename

  has_and_belongs_to_many :extracurriculars
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :majors
  has_and_belongs_to_many :sports
  has_and_belongs_to_many :frat_sororities
  has_and_belongs_to_many :groups, :join_table => :members_groups

  has_many :folders
  has_many :broadcasts
  has_many :recommendations
  has_many :notebooks
  has_many :notes
  has_many :enrollments
  has_many :offerings, :through => :enrollments
  has_many :courses, :through => :offerings
  belongs_to :school
  has_many :authentications, :dependent => :destroy
  has_many :session_invites
  has_many :study_sessions, :through => :session_invites
  has_many :posts
  has_many :group_invites
  has_many :questions
  has_many :answers
  has_many :activity_messages
  has_many :calendars
  has_many :searches
  has_one :group, :foreign_key => :owner_id
  has_many :permissions
  has_one :privacy_setting
  has_many :has_likes
  
  accepts_nested_attributes_for :enrollments, :privacy_setting
  
  scope :active_users, where(:active => true)

  scope :other_than, lambda {|users| where(User.arel_table[:id].not_in(users.any? ? users.map(&:id) : [0])) }
  scope :with_attribute, lambda {|member| all.collect{|u| u unless u.send(member).nil? || u.send(member).blank? }.compact}
  scope :has_extracurricular, lambda { |extracurricular_id| all.collect{|u| u if u.extracurricular_ids.include? extracurricular_id}}
  scope :has_frat_sororities, lambda { |frat_sorority_ids| joins("join frat_sororities_users on frat_sororities_users.user_id = users.id").where({ frat_sororities_users: { frat_sorority_id: frat_sorority_ids}})}
  scope :has_sports, lambda { |sports_ids| joins("join sports_users on sports_users.user_id = users.id").where({ sports_users: { sport_id: sports_ids}})}
  
  validates :custom_url, 
    :format => {:with => /^[a-z0-9]+[-a-z0-9]*[a-z0-9]+$/i, :message => "may only use letters and numbers."},
    :uniqueness => true  
  validates_numericality_of :gpa, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 4.0, :allow_nil => true
  #validate :name_should_be_present
  validate :email_should_be_present
  validate :school_should_be_present
  
  before_validation do
    self.school = School.from_email self.email if self.email and self.school_id.nil?
    self.roles << Role.find_by_name("Student") if self.role_ids.nil?
  end
  validates_attachment_content_type :avatar, :content_type =>  ["image/jpeg", "image/jpg", "image/x-png", "image/pjpeg", "image/png", "image/gif"], :message => "Oops! Make sure you are uploading an image file." 
  validates_attachment_size :avatar, :less_than => 10.megabyte, :message => "Max Size of the image is 10M"
  
  after_create do
    welcome_message
    if school
      Recommendation.populate_user([self.id])
      update_rankings_for_school
    end
    create_privacy_setting
    create_initial_folders
  end

  
  after_destroy do
    update_rankings_for_school_destroy
  end

  searchable :auto_remove => true do
    text :name
    text :school_name
    text :course_names
    text :fraternity
    text :sorority
    text :extracurriculars
    text :major
    text :bio
    string :name
    string :last_name
    string :school_name
    string :major do
      if self.major
        major.downcase
      end
    end
    integer :school_id
    integer :plusminus
    integer :grad_year
    boolean :shares_with_everyone
    boolean :active
  end

  PROTECTED_PROFILE_ATTRBUTES = %w(email)
  
  def create_privacy_setting
    self.privacy_setting = PrivacySetting.new  
  end
  
  def create_initial_folders
    Folder.create(:name => "Other", :user_id => self.id)
    Folder.create(:name => "Archived Work", :user_id => self.id)
    Folder.create(:name => "Notes Shared With You", :user_id => self.id)
  end
  
  def self.index_sitemap
    all_users = User.all
    File.open("#{Rails.root}/public/sitemap.txt", "w") do |f|
      all_users.each do |u|
        f.puts "http://www.studyhall.com/#{u.custom_url}"
      end
    end
  end
  
  def welcome_message
    @sender = User.find(41)
    @receiver = []
    @receiver << self
    subject = "Welcome to StudyHall!"
    body = "<p>With StudyHall, you can easily add your courses, connect with classmates, and share your notes to make your academic life, simpler.</p>
    <p>To get started, we recommend you:</p>
    <ul>
    <li>Make sure your personal profile is 100% complete.</li>
    <li>Add your courses.</li>
    <li>Upload and share your notes from class.</li>
    <li>Invite your friends to join StudyHall!</li>
    </ul>
    <p></p>
    <p>
    StudyHall is going to help you do much better, together.
    <br />
    <p></p>
    <p>
    Best,
    <br />
    <b>Ross and Ben</b>
    <br />
    Co-Founders, StudyHall.com
    </p>
    "
    @success = @sender.send_message?(subject, body, *@receiver)
  end

  def update_rankings_for_school
    @school = School.find(self.school_id)
    @school.user_ids.each do |id|
      rec_to_update = Recommendation.find_by_user_id(id)
      if id != self.id and !rec_to_update.nil?
        rec_to_update.conn_cda.merge!({self.id => 0})
        rec_to_update.rank_cda.merge!({self.id => [0.0,0]})
        rec_to_update.save!
      end
    end 
  end
  def update_rankings_for_school_destroy
    @school = School.find(self.school_id)
    @school.user_ids.each do |id|
      rec_to_update = Recommendation.find_by_user_id(id)
      if id != self.id and !rec_to_update.nil?
        rec_to_update.conn_cda.delete(self.id)
        rec_to_update.rank_cda.delete(self.id)
        rec_to_update.save!
      end
    end 
  end
  
  def current_broadcasts
    Broadcast.where("user_id = ? AND current = ?", self.id, true).recent
  end

  def documents(type=nil)
    type ? Note.where("user_id = ? AND doc_type = ?", self.id, type) : self.notes
  end

  def name_should_be_present
    self.errors[:first_name] = "cannot be blank" if (first_name.blank? && read_attribute(:active) == true)
    self.errors[:last_name] = "cannot be blank" if (last_name.blank? && read_attribute(:active) == true)
  end
  
  def school_should_be_present
    self.errors[:school_id] = "No school was found with that email address." if (school_id.blank? && read_attribute(:active) == true)
  end
  
  def email_should_be_present
    self.errors[:email] = "cannot be blank" if (email.blank? && read_attribute(:active) == true)
  end

  def activity
    activity_messages.order('created_at DESC')
  end

#  def bonus_activity(page = nil)
#    activity_messages.order('created_at DESC')
#    paginate :page => page, :per_page => APP_CONFIG['per_page'] if page
#  end

  def photo_url(size = :medium)
    if avatar.file?
      avatar.url(size)
    else
      "/assets/generic_avatar_#{size.to_s}.jpg"
    end
  end


 # def omniauth
 #   request.env["omniauth.auth"]
 # end

  def avatar?
    !avatar_url.include?('generic_avatar')
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def storage_size
    total_size = 0
    self.notes.each do |note|
      total_size = number_to_human_size(File.size("#{note}")) + total_size
    end
    total_size    
  end
  
  def name
    full_name
  end
  
  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a 
    password = ""
    1.upto(len) { |i| password << chars[rand(chars.size-1)]}
    return password
  end
  
  def title_name
    name.titleize
  end
  
  def trunc_name(length, titleize=true)
    tname = titleize ? title_name : name
    tname.length > length ? "#{tname.slice(0, length)}..." : tname
  end
  
  def school_name
    school.try(:name)
  end
  
  def course_names
    courses.map(&:title).join(" ")
  end

  def voted_for?(user)
    vote = user.votes.where(:voter_id => self).first
    vote.nil? ? false : vote.vote
  end

  def can_edit?(note)
    if self.permissions.find_by_permission_setting_id(note.permission_setting.id)
      self.permissions.find_by_permission_setting_id(note.permission_setting.id).can_edit
    end
  end

#  def can_share_with_offering?(offering_id)
#    if Offering.where(:id => offering_id)
    

  def can_view?(note)
    if note.permission_setting.school_can_view
      return true
    elsif note.permission_setting.buddies_can_view and self.friend_with?(note.owner)
      return true
    elsif self.permissions.find_by_permission_setting_id(note.permission_setting.id)
      return true
    else
      return false
    end
  end
  

  def can_copy?(note)
    if note.permission_setting.school_can_copy
      return true
    elsif note.permission_setting.buddies_can_copy and self.friend_with?(note.owner)
      return true
    elsif self.permissions.find_by_permission_setting_id(note.permission_setting.id)
      self.permissions.find_by_permission_setting_id(note.permission_setting.id).can_copy
    end
  end
  
  def has_role?(role)
    self.roles.include? role
  end
  
  def admin?
    self.roles.include?(Role.find_by_name "Admin")
  end
  
  def editable_by?(user)
    (self == user) || (user.roles.include?(Role.find_by_name "Admin"))
  end

  def added_course?(course)
    self.courses.where(id: course.id).any?
  end

  def activate!
    update_attribute(:active, true)
  end
  
  def deliver_password_reset_instructions!  
    reset_perishable_token!  
    Notifier.password_reset_instructions(self).deliver
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.activation_instructions(self).deliver
  end

  def deliver_welcome!
    reset_perishable_token!
    Notifier.welcome(self).deliver
  end

  def deliver_followed_notification!(follower)
    Notifier.user_following(follower,self).deliver
  end
  
  def avatar_url(size = nil)
    photo_url(size)
  end
  
  def has_avatar?
    self.avatar_file_name
  end
  
  def male?
    self.gender == "Male"
  end
  
  def female?
    self.gender == "Female"
  end
  
  # TODO: Evaluate for refactor
  def split_attribute_list(attributes, model, collection_method)
    ids = []
    return ids if (attributes.blank? or attributes.empty?)
    attributes = attributes.split(",").delete_if {|a| a.strip! == ""}
    attributes.each do |a|
      new_record = model.new(name: a.strip)
      if new_record.save
        ids << new_record.id
      else
        ids << model.find_by_name(a.strip).id
      end
    end
    ids << self.send(collection_method)
    ids.flatten
  end
  
  def profile_completion_percentage
    count = 0.0
    total = 0.0
    [self.photo_url, self.enrollments, self.school_id, self.majors, self.sports].each do |member|
      count += 1 unless (member.blank? || member =~ /\/assets\/generic_avatar\_\w*.png/)
      total += 1
    end
    (count/total * 100).to_i
  end
  
  # fields not in profile wizard completion
  def profile_except_wizard_completion_count
    [self.bio, self.custom_url, self.school_id, self.majors, self.gpa, self.gender, self.extracurriculars].reject { |member| member.blank? }.count
  end
  
  def profile_complete?
    self.profile_completion_percentage >= 100
  end

  def blank_form_finder
    count = 0
    [self.majors, self.sports, self.frat_sororities, self.photo_url, self.enrollments].each do |member|
      count += 1
      if (member.blank? || member =~ /\/assets\/generic_avatar\_\w*.png/)
        return count
      end
    end
    count + 1
  end

  def next_blank_form_finder
    count = 0
    blank_index = 0
    [self.majors, self.sports, self.frat_sororities, self.photo_url, self.enrollments].each do |member|
      count += 1
      if (member.blank? && blank_index == 1)
        puts "am i here...right"
        return count
      end
      if (member.blank? || member =~ /\/assets\/generic_avatar\_\w*.png/)
        blank_index += 1
      end
    end
    count + 1
  end
  
  def extracurriculars_list
    self.extracurriculars.collect {|e| e.name}.join(",")
  end
  
  def all_messages(attributes = {})
    recieved = Message.where({
      :received_messageable_id => self.id, 
      :received_messageable_type => self.class.to_s,
      :parent_id => nil, :spam => 0, :abuse => 0
      }.merge(attributes)).order("id desc")
    
    sent = MessageCopy.where({
      :sent_messageable_id => get_sender_id(attributes), 
      :sent_messageable_type => self.class.to_s,
      :parent_id => nil, :spam => 0, :abuse => 0
      }.merge(attributes)).order("id desc")
    
    (recieved + sent).sort { |a, b| b.created_at <=> a.created_at }
  end
  
  def alpha_ordered_notebooks(filter_params = {})
    nbs = notebooks.where(filter_params)
    compact_names = nbs.collect{|n| n.course.try(:compact_name)}.uniq.compact.sort
    ordered_notebooks = []
    compact_names.each do |cn|
      notebook_for_course = []
      nbs.each do |notebook|
        notebook_for_course << notebook if notebook.course.try(:compact_name) == cn
      end
      ordered_notebooks << notebook_for_course.sort_by!{|n| n.name}
    end
    ordered_notebooks << nbs.collect{|n| n if n.course.nil?}.compact.sort_by{|n| n.name}
    ordered_notebooks.flatten.compact
  end
  
  def get_sender_id(attributes)
    sender_id = attributes[:sender_id] || self.id
    attributes.delete :sender_id if attributes[:sender_id]
    sender_id
  end
  
  # Apply Omniauth attributes to the user if the attributes exist
  def apply_omniauth(omniauth)
    provider = omniauth.provider

    if provider == 'facebook'
      apply_facebook(omniauth)
    elsif provider == 'google'
      apply_google(omniauth)
    #elsif provider == 'linkedin'
    #  apply_linkedin(omniauth)
    end

    authentications.build(provider: provider, uid: omniauth.uid, user_id: id)
  end



  def facebook
    begin
      @facebook ||= Koala::Facebook::API.new(omniauth_facebook_token)
      block_given? ? yield(@facebook) : @facebook
   # end
    rescue Koala::Facebook::APIError => e
   # logger.info e.to_s
      nil # or consider a custom null object
    end
  end

  def friends_count
    facebook { |fb| fb.get_connection("me", "friends").size }
  end


  def share_signin
    begin
      facebook.put_connections("me", "feed", {:message => 'I just signed up for a StudyHall account. Get on my level y\'all. #killinit #getyourstudyon', :link => 'http://www.studyhall.com/'})
    rescue
      nil
    end
  end


  def make_post(text, fb_friends)
    if(!omniauth_facebook_token.nil?)
      fb = Koala::Facebook::API.new(omniauth_facebook_token)
      begin
        fb.put_connections("me", "feed", { :message => text, :place => '103546079768461', :tags=> fb_friends })
      rescue
        fb.put_connections("me", "feed", { :message => text, :place => '103546079768461' } )
      end
    end
  end
  
  def share_fifth_note
    if(!omniauth_facebook_token.nil?)
      fb = Koala::Facebook::API.new(omniauth_facebook_token)
      begin
        #what is going on with "place?"
        fb.put_connections("me", "feed", { :message => "I just uploaded my 5th note on Studyhall.com." , :place => '103546079768461' } )
      rescue
        nil
      end
    end
  end
  
  def notes_size
    notes.sum(:doc_file_size)
  end
  
  def notes_too_big
    notes_size > 5000000 #5mb
  end
  
  def get_fb_id
    if(!omniauth_facebook_token.nil?)
      begin
        fb = Koala::Facebook::API.new(omniauth_facebook_token)
        fb.get_object("me")["id"]
      rescue
        nil
      end
    end
  end


  def share_studyhall(buddy_ids)
    master_id = get_fb_id
    master_name = first_name + " " + last_name
    first_user_post = "I just studied on Studyhall.com. Definitely not going to fail that test. #iloveknowledge"
    fb_friends = ""
    buddy_ids.each do |bi|
      friend = User.where(:id => bi).first
      if(!friend.omniauth_facebook_token.nil?)
        begin
          friend.make_post(master_name + " just invited me to study on Studyhall.com. I'm feeling smarter already. #nerdbombing", master_id)
          if(fb_friends.length == 0)
            fb_friends += friend.get_fb_id
          else
            fb_friends += ',' + friend.get_fb_id
          end
        rescue
          nil
        end
      end      
    end
    #now make the inviting user's post
    begin
      self.make_post(first_user_post, fb_friends)
    rescue
      nil
    end
  end

  #pass in array of buddy_ids
  def share_course(buddy_ids)
    all_friends = []
    fgc = user.facebook.get_connections("me", "friends")
    fgc.each do |f|
      all_friends[f['id']] = f['name']
    end
    (0..1000).each do |i|
      fgc = fgc.next_page
      break if(fgc.nil?)
      fgc.each do |f|
        all_friends[f['id']] = f['name']
      end
    end
    found_friends = "I just studied on Studyhall.com!"
    buddy_ids.each do |bid|
      if all_friends.has_key?(bid.to_s)
        found_friends += " @[#{bid}:#{all_friends['name']}]"
      end
    end
    user.facebook.post_connections("me", "feed", :message => found_friends)
  end

  #def self.contains_custom_url?(custom)
    #User.all.collect(&:custom_url).include?(custom)
  #end
  
  private
  
  def apply_facebook(omniauth)
    if omniauth.extra.raw_info
      self.update_attribute('first_name', omniauth.extra.raw_info.first_name) unless self.first_name
      self.update_attribute('last_name', omniauth.extra.raw_info.last_name) unless self.last_name
      self.update_attribute('bio', omniauth.extra.raw_info.bio) unless self.bio
      self.update_attribute('gender', omniauth.extra.raw_info.gender.humanize) unless self.gender
      self.update_attribute('avatar', open("https://graph.facebook.com/#{omniauth.uid}/picture?type=large")) unless self.avatar?
      #set_school_and_major_from_facebook(omniauth)
      #apply_custom_url(omniauth.extra.raw_info.username)
    end
  end

  #def apply_custom_url(custom)
    #self.update_attribute('custom_url', User.contains_custom_url?(custom) ? nil : custom)
  #end

  def apply_google(omniauth)
    full_name = omniauth.info.name.split(' ')
    self.first_name =  full_name.first
    self.last_name = full_name[1..-1].join(' ')
  end

  def set_school_and_major_from_facebook(omniauth)
    omniauth.extra.raw_info.education.each do |education|
      if education.type == 'College'
        school = School.find_by_name(education.school.name)
        self.school = school if school

        major = Major.find_by_name(education.concentration.first.name)
        self.majors << major if major
        self.grad_year = education.year.name.to_i
      end
    end

  end
  
  
  # The following two methods are implemnented as a workaround for the issue 
  # described in Paperclip Issue 603 on Github. 
  # Namely: nobody wants to make Paperclip responsible for storing URL friendly
  # filenames because it seems like the wrong place to implement that functioanlity. 
  # Lazy Thoughtbotters. 
  def paperclip_hack_filename
    extension = File.extname(avatar_file_name).gsub(/^\.+/, '')
    filename = avatar_file_name.gsub(/\.#{extension}$/, '')
    self.avatar.instance_write(:file_name, "#{hack_filename(filename)}.#{hack_filename(extension)}")
  end
  def hack_filename(s)
    s.downcase!
    s.gsub!(/'/, '')
    s.gsub!(/[^A-Za-z0-9]+/, ' ')
    s.strip!
    s.gsub!(/\ +/, '-')
    return s
  end

end

class User::NotAuthorized < StandardError; end
