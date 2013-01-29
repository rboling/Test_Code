class Question < ActiveRecord::Base

  belongs_to :offering
  belongs_to :group
  belongs_to :user
  #belongs_to :notebook
  #belongs_to :note
  #belongs_to :study_session
  belongs_to :parent, :class_name => "Question"
  has_many :answers , :foreign_key => :parent_id
  has_many :postings
  
  scope :recent, :limit => 20, :order => 'updated_at DESC'
  scope :top_level, lambda {where :parent_id => nil}
  scope :for_offering, lambda {|offering| where :offering_id => offering.id}
  scope :by_user, lambda { |user| where :user_id => user.id}
  
  
  def answer?
    self.class.name == "Answer"
  end
  
  def has_answers?
    answers.collect{|c| c unless c.new_record?}.any?
  end
  
  def has_postings?
    postings.collect{|c| c unless c.new_record?}.any?
  end

  def posting?
    self.class.name == "Posting"
  end

  def self.filter(filter, offering)
    questions = offering.questions
    questions = questions.where("flagged_as = ?", filter[:question][:flagged_as])

    #  if filter[:question][:name]
    #    study_sessions = study_sessions.where(["name like ?", "%#{filter[:study_session][:name]}%"])
    #  end
    #  if filter[:study_session][:offering_id]
    #    study_sessions = study_sessions.where("offering_id = ?", filter[:study_session][:offering_id])
    #  end
    #end
    #if filter[:user_ids]
    #  users = User.where(:id => filter[:user_ids]).all
    #  study_sessions = study_sessions.with_users(filter[:user_ids])
    #end
    #if filter[:start_date] || filter[:end_date]
    #  study_sessions = study_sessions.in_range(filter[:start_date], filter[:end_date])
    #end
    questions
  end

end
