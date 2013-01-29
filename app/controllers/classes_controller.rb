class ClassesController < ApplicationController

  before_filter :set_action_bar

  def index
    @classes = @current_user.offerings
  end
  
  def show
   if request.xhr?
    dept_name = params[:dept_name] #this is the department name selected in the chosen dropdown
    number = params[:number] #this is the course number
    prof_last = params[:prof_last]
    next_action = params[:next]
    if(next_action == "add_course") #this is when the user clicks 'course not here'
      @course = Course.where(:department => dept_name, :school_id => current_user.school.id, :number => number).first
      render :text => dept_name
    elsif(next_action == "add_prof_last") #this is when the user clicks continue for adding a new course
      prof_ids = Instructor.select(:last_name).where(:school => current_user.school.name).uniq.collect{|c| c.last_name }
      prof_name_string = ''
      prof_ids.each do |p|
        prof_name_string << '<option value ="' + p.to_s + '">' + p + '</option>'
      end
      render :text => prof_name_string
    elsif(next_action == "add_prof_first") #this is when user select the last name of a professor
      @course = Course.where(:department => dept_name, :school_id => @current_user.school.id, :number => number).first
      prof_ids = Instructor.select(:first_name).where(:school => current_user.school.name, :last_name => prof_last).uniq.collect{|c| c.first_name }
      prof_first_name_string = ''
      prof_ids.each do |p|
        prof_first_name_string << '<option value ="' + p.to_s + '">' + p + '</option>'
      end
      render :text => prof_first_name_string
    elsif(next_action == 'number_select') #occurs when user selects department
      course_nos = Course.select(:number).where(:school_id => @current_user.school.id, :department => dept_name).uniq.collect{|c| c.number }
      course_nos = course_nos.map{|cn| cn }.sort!
      course_no_string = ''
      course_nos.each do |cn|
        course_no_string << '<option value="' + cn.to_s + '">' + cn.to_s + '</option>'
      end
      render :text => course_no_string
    elsif(next_action == "prof_select") #occurs when user selects course number
      @course = Course.where(:department => dept_name, :school_id => @current_user.school.id, :number => number).first
      prof_ids = Offering.select(:instructor_id).where(:course_id => @course.id).uniq.collect{|c| c.instructor_id }
      prof_name_string = ''
      prof_ids.each do |p|
        unless p == nil
          prof_name_string << '<option value ="' + p.to_s + '">' + Instructor.find(p).full_name + '</option>'
        end
      end
      render :text => prof_name_string
    else #occurs when user selects professor(aka offering) either a pre-existing one or a new one
      @course = Course.where(:school_id => @current_user.school.id, :department => dept_name, :number => number).first
      course_name = Course.select(:title).where(:school_id => @current_user.school.id, :department => dept_name, :number => number).collect{|c| c.title }           
      course_name = Course.select(:title).where(:school_id => @current_user.school.id).collect{|c| c.title }   
      #Originally:
      title = params[:title]
      unless @course.nil? #this is for when
        render :text => dept_name + ' ' + number + ': ' + @course.title
      else
        render :text => dept_name + ' ' + number + ': ' + title
      end
    end
    else
      @class = Offering.find(params[:id])
      @course = @class.course
      @textbook = Textbook.where(:course_id => @course.id).first
      @classmates = @class.classmates(current_user)
      @posts = @class.posts.where("post_type <= ?", 'class').recent.top_level
      @questions = @class.questions.recent.top_level

      @shared_study_sessions = @class.study_sessions.viewable_by nil
      @appropriate_offering_permissions = OfferingPermission.where(:offering_id => @class.id)
      @shared_notes = []
      @appropriate_offering_permissions.each do |note|
        @shared_notes << Note.where(:id => note.note_id).first
        @class.users.each do |user|
          Note.where(:id => note.note_id).first.permission_setting.permissions.create(:user_id => user.id, :note_id => note.note_id, :can_view => note.can_view, :can_edit => note.can_edit, :can_copy => note.can_copy, :permission_setting_id => note.permission_setting_id, :offering_id => note.offering_id)
        end
      end
        
      flash[:action_bar_message] = @course.title
      
    end
  end
  
  def new
    @enrollment = Enrollment.new
    #@offerings = Offering.where(school_id: current_user.school.id).includes(:course, :school, :instructor)
    #@offerings = current_user.school.offerings.includes(:course, :instructor)
    @user = @current_user
    respond_to do |format|
      if request.xhr?
        @modal_link_id = params[:link_id]
      end
      format.js
    end
  end
  
  def create_prof
    prof_last = params[:prof][:last]
    prof_first = params[:prof][:first]
    @prof = Instructor.where(:first_name => prof_first, :last_name => prof_last).first
    if (@prof.nil?)
      @prof = Instructor.new
      @prof.school = current_user.school.name
      @prof.first_name = prof_first
      @prof.last_name = prof_last
      @prof.save
    end
    render :nothing => true
  end
  
  def create
    department = params[:class][:department]
    if params[:class_number].blank?
      number = params[:class][:number].first
    else
      number = params[:class_number]
    end
    @course = Course.where(:department => department, :number => number.to_s, :school_id => current_user.school.id).first
    if(@course.nil?)
      @course = Course.new
      @course.school = current_user.school
      @course.department = department
      @course.number = number.to_s
      @course.title = params[:class_title]
      @course.save
    end
    if (params[:prof_last][:number][0] != "Last Name" and params[:prof_last][:number][0].empty? == false)
       @professor = Instructor.where(:first_name => params[:prof_first][:number][0], :last_name => params[:prof_last][:number][0]).first
       if(@professor.nil?)
         @professor = Instructor.create(:first_name => params[:prof_first_name][0], :last_name => params[:prof_last_name][0], :school => current_user.school.name)
       end
       professor_id = @professor.id
    elsif (params[:prof][:last].empty? == false)
      @prof = Instructor.where(:last_name => params[:prof][:last], :first_name => params[:prof][:first], :school => current_user.school.name).first
      if (@prof.nil?)
        @prof = Instructor.new
        @prof.school = current_user.school.name
        @prof.first_name = params[:prof][:first]
        @prof.last_name = params[:prof][:last]
        @prof.save
      end
      professor_id = @prof.id
    else
      professor_id = params[:prof][:number]
    end
    @offering = Offering.where(:course_id => @course.id, :instructor_id => professor_id).first
    if(@offering.nil?)
      @offering = Offering.new
      @offering.course_id = @course.id
      @offering.course = @course
      @offering.school = current_user.school
      @offering.instructor_id = professor_id
      @offering.term = "Fall 2012"
      @offering.save
    end
    @enrollment = Enrollment.new
    @enrollment.offering = @offering
    @enrollment.user = current_user
    @user = current_user
    
    #add the calendar event
    days = ''
    days << '1' if(params[:mon] == 'on')
    days << '2' if(params[:tue] == 'on')
    days << '3' if(params[:wed] == 'on')
    days << '4' if(params[:thu] == 'on')
    days << '5' if(params[:fri] == 'on')
    
    @calendar = Calendar.new
    @calendar.update_attributes({ :days => days, :course_id => @offering.id, :time_start => params[:class_start][:time], :time_end => params[:class_end][:time], :user_id => current_user.id, :course_name => @course.title })
    if @enrollment.save
     # current_user.friends.each do |friend|
     #   message_body = ActivityRenderer.new.generate_message(friend, 'course_add', :user => current_user, :offering => @offering)
     #   ActivityMessage.create(:user => friend, :body => message_body, :activist => current_user)
     # end
      @calendar.save
      if request.xhr? and @offering.verified == true
        render partial: 'users/course_list', collection: current_user.offerings, as: :offering, :locals => {:wrapper_class => "wrapper_large"}
      elsif request.xhr?
        render partial: 'users/course_list', collection: current_user.offerings, as: :offering, :locals => {:wrapper_class => "wrapper_large"}
      else
        redirect_to classes_path
      end
    else
      @user = current_user
      render :nothing => true
    end
  end

  def create_questions
    @question_type = params[:question_type]
    @class = Offering.find params[:class_id]
    @question = Question.new
    @question.user_id = current_user.id
    @question.text = params[:message]
    @question.flagged_as = params[:flagged_as]
    @question.reported = 0
    if @question_type == 'group'
      @question.question_type = 'group'
      @question.group_id = params[:class_id]
    else
      @question.question_type = 'class'
      @question.offering_id = params[:class_id]
    end
    if @question.save
      @offering = Offering.find(params[:class_id])
      @questions = Offering.find(params[:class_id]).questions.recent.top_level.page(params[:page])
      respond_to do |format|
        format.js #{ redirect_to "/classes/#{@class.slug}" }
        format.html #{ redirect_to @class }
       # format.html
      end
    end
   # push_broadcast(:question_asked, :offering_id => @class.id)
  end

  def create_answers
    @class = Offering.find params[:class_id]
    @question_type = params[:question_type]
    @answer = Answer.new(params[:answer])
    if @answer_type == 'group'
      @answer.group_id = params[:group_id]
    else
      @answer.offering_id = params[:class_id]
    end
    @answer.user = current_user
    @questions = Offering.find(params[:class_id]).questions.recent.top_level.page(params[:page])
    @offering = Offering.find(params[:class_id])
    if @answer.save
      respond_to do |format|
        format.js #{ redirect_to "/classes/#{@class.slug}" }
        format.html #{ redirect_to @class }
      end
    end
  end

  def create_postings
    @class = Offering.find params[:class_id]
    @question_type = params[:question_type]
    @question_id = params[:question_id]
    @user_id = params[:user_id]
    @posting = Posting.new(params[:posting])
    @posting.question_id = @question_id
    @posting.question_type = @question_type
    if @posting_type == 'group'
      @posting.group_id = params[:group_id]
    else
      @posting.offering_id = params[:class_id]
    end
    @posting.user = current_user
    @questions = Offering.find(params[:class_id]).questions.recent.top_level.page(params[:page])
    @offering = Offering.find(params[:class_id])
    if @posting.save
      respond_to do |format|
        format.js #{ redirect_to "/classes/#{@class.slug}" }
        format.html #{ redirect_to @class }
      end
    end 
  end
  
  def invite
    unless params[:email].blank?
      if params[:class_id] == "1"
        @offering = current_user.enrollments.last.offering
      else
        @offering = Offering.find(params[:class_id])
      end
      @email = params[:email] + '@' + current_user.school.domain_name
      if User.find_by_email(@email)
        @user = User.find_by_email(@email)
        Notifier.user_class_invite_email(@user, current_user, @offering).deliver
      else
        @signup = Signup.new
        @signup.email = @email
        if @signup.save
          Notifier.class_invite_email(@signup, current_user, @offering).deliver
        else
          @signup = Signup.find_by_email(@email)
          @signup.reset_perishable_token!
          Notifier.class_invite_email(@signup, current_user, @offering).deliver
        end
      end
    else
      @offering = current_user.enrollments.last.offering
    end
    if params[:done] == "true" or params[:email].blank?
      render :nothing => true
    else
      render :text => @email
    end
  end
  
  def autocomplete
    @search = Sunspot.search Course do
      fulltext params [:title]
      paginate :page => 1, :per_page => 5
    end
    result = @search.results.map {|r|
      h = {}
      h[:type] = "Course"
      h[:label] = truncate(r.title, :length => 30)
      h[:value] = r.title
      h
    }
    render :json => result.to_json
  end
  
  def edit
    
  end
  
  def update
    @course = Course.find(params[:id])
    @course.title = params[:class][:title]
    @course.save
    render :text => @course.title
  end
  
  def destroy
    @enrollment = @current_user.enrollments.find_by_offering_id params[:id]
    @enrollment.destroy
    redirect_to :controller => "home", :action => "index"
  end
  
  def offerings_for_school
    @school = School.find(params[:school_id], :include => :offerings)
    @offerings = @school.offerings(:include => [:course, :instructor])
    
    if request.xhr?
      render :json => { :offerings => @offerings.collect {|o| o.course_listing}, :offering_ids => @school.offering_ids }
    end
  end
  
  def classmates
    @class = @current_user.offerings.find(params[:class_id])
    @users = @class.classmates(current_user)
    @title = "Classmates"
    render "shared/users_list.js.erb"
  end

  def view_questions
    @class = @current_user.offerings.find(params[:class_id])
    @questions = []
    @class.questions.each do |question|
      if question.flagged_as == 'question'
        @questions << question
      end
    end
    #render :partial => 'questions/list_item.html.erb', :locals => {:questions => @questions, :question_type => 'class'}
    redirect_to '/home'
  end

  def view_comments
    @questions = []
    @class.questions.each do |question|
      if question.flagged_as == 'posting'
        @questions << question
      end
    end
    #render :partial => 'questions/list_item.html.erb', :locals => {:questions => @questions, :question_type => 'class'}
    redirect_to '/home'
  end
  

  def find_questions
    if params[:filter]
      @filtered_results = true
      flash.now[:action_bar_message] = "Filtered questions "
      questions = Question.filter(params[:filter], @class).recent.top_level 
#      @questions = @class.questions.recent.top_level
    else
      @filtered_results = false
      @questions = @class.questions.recent.top_level
    end
    @questions
  end

end
