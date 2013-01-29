module UsersHelper
  
  def fraternity_or_sorority_label(user)
    case user.gender
    when 'Male'
      'Fraternity'
    when 'Female'
      'Sorority'
    else
      'Fraternity or Sorority'
    end
  end
  
  def vote_help_text
    "Students can up or down vote their classmates to give others an idea of how helpful they are as a study buddy."
  end
  
  def gpa_help_text
    "Your GPA is important: it helps you and your fellow students make better decisions about study partners. Please enter your GPA as a 3 digit number on a 4.0 scale. For example: 3.96"
  end
  
  def user_protected_profile?(user, attrubute)
    User::PROTECTED_PROFILE_ATTRBUTES.include? attrubute.to_s
  end
  
  def greek_affiliation
     @user.male? ? "#{@user.fraternity}" : "#{@user.sorority}"
  end
  
  def sybling_type
    @user.male? ? "brother" : "sister"
  end
  
  def selected_courses_for(user)
    user.enrollments.collect {|e| e.offering.id}
  end
  
  def generate_group_links_for(user, activity)
    group_name = user.school.name + ' ' + activity
    @group = Group.where(:group_name => group_name).first
    if @group.nil?
      @group = Group.new
      @group.update_attributes(:owner_id => user.id, :active => true, :admin_approval => false, :privacy_open => true, :privacy_closed => false, :privacy_secret => false, :group_name => group_name)
    end
    @group.members << user unless @group.members.include?(user)
    return "<a href=\"/groups/#{@group.id}\">" + activity + "</a>"
  end
  
  def html_greek_string_for(user)
    "a #{sybling_type} in " + generate_group_links_for(user, user.frat_sororities.map(&:name).first)
    #{content_tag(:span, user.frat_sororities.map(&:name).join(", "), :class => 'highlight_text')}"
  end
  
  def html_school_name_for(user)
    "#{content_tag(:span, user.school.try(:name), :class => 'org')}"
  end
  
  def html_sports_for(user)
    #"likes #{content_tag(:span, user.sports.map(&:name).join(", "), :class => 'highlight_text')}"
    sports_linx = []
    user.sports.map(&:name).each do |s|
      sports_linx << generate_group_links_for(user, s)
    end
    sports_linx.join(', ')
  end
  
  def html_major_string_for(user)
    #"majors in #{content_tag(:span, user.majors.map(&:name).join(", "), :class => 'highlight_text')}"
    majors_linx = []
    user.majors.map(&:name).each do |s|
      majors_linx << generate_group_links_for(user, s)
    end
    majors_linx.join(', ')
  end
  
  def html_grad_year_for(user)
    #"class of #{content_tag(:span, user.grad_year, :class => 'highlight_text')}"
    "class of " + generate_group_links_for(user, user.grad_year.to_s)
  end
  
  def html_courses_for(user)
    
  end
  
  def html_profile_detailed_info_for(user)
    output = []
    output << html_school_name_for(user) if user.school
    output << html_grad_year_for(user) if user.grad_year
    output << html_greek_string_for(user) unless user.frat_sororities.blank?
    output << html_major_string_for(user) unless user.majors.blank?
    output << html_sports_for(user) unless user.sports.blank?
    output.join(', ').capitalize.html_safe if !output.empty?
  end
  
end
