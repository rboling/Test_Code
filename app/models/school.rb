class School < ActiveRecord::Base
  
  has_many :courses
  has_many :offerings
  has_many :course_offering_imports
  has_many :users
  has_many :rss_entries
  has_many :recommendations
  has_many :signups
  has_many :majors
  has_many :sports
  has_many :departments
  
  scope :active_schools, where(:active => true)
  scope :inactive_schools, where(:active => false)
  
  validates_presence_of :name
  validates_uniqueness_of :name 
  
  scope :has_rss_link, where("rss_link IS NOT NULL")

  def latest_news
    rss_entries.order('created_at DESC')
  end
  
  def self.from_email(email)
    #domain = String.new
    domain = email.split("@")[1].to_s rescue nil
    if domain.include?(".edu")
      unless self.find_by_domain_name(domain)
        School.create!(:name => "Inactive School - #{domain}", :domain_name => domain, :active => false)
      end
      self.find_by_domain_name(domain)
    else
      nil
    end
  end
end
