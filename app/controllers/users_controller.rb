class UsersController < ApplicationController
  
  before_filter :require_no_user_or_admin, :only => [:new, :create]
  before_filter :require_user, :only => [:edit, :update, :account, :welcome]
  before_filter :fetch_user, :only => [:show, :edit, :update, :destroy, :profile_wizard, :account, :welcome]
  before_filter :set_action_bar, :only => [:show, :edit]
  before_filter :check_first_last_name, :only => :profile_wizard
  skip_before_filter :require_first_last_name, :only => [:profile_wizard, :update, :show,]
  skip_before_filter :require_not_new_user, :only => [:welcome, :update, :add_class]
  skip_before_filter :require_first_last_name, :only => [:profile_wizard, :update, :show, :welcome]

  def make_admin
    @modal_link_id = params[:modal_link_id]
    @group = Group.find(params[:group_id])
    @user = User.find(params[:user_id])
    @group.admins << User.find(@user)
    respond_to do |format|
      format.js
    end
  end
  
  def index
    if current_user
      redirect_back_or_default current_user
    else
      redirect_to login_path
    end
  end
  
  def show
    redirect_to login_path, flash: {notice: "You must log in to view that profile"} unless @user.googleable? || current_user
    if !current_user
      @googleview = true
    else
      @form_list = %w[name affiliations gpa bio photo invitations]
      @enrollment = Enrollment.new

      if current_user.blank_form_finder <= 3 
        @com_form = 'affiliations_form'
      elsif current_user.blank_form_finder == 4
        @com_form = 'photo_form'
      else
        @com_form = 'invitations_form'        
      end
    end
    if params[:tour]
      flash[:action_bar_message] = 'Welcome to StudyHall!'
    else
      if @user.majors.blank?
        flash[:action_bar_message] = "#{@user.name}"
      else
        flash[:action_bar_message] = "#{@user.name} - #{@user.majors.map(&:name).join(", ")}"
      end
    end
  end

  def edit
      unless @user.editable_by? @current_user
        redirect_back_or_default @user
      end
      flash[:action_bar_message] = "Click the parts of the profile you want to edit."
  end
    
  def update
    #majors before update

    @majors_b = current_user.major_ids
    @user = current_user
    check_tour_mode
    check_completion_mode
    check_other_mode
    if params[:rel_form] == 'course_form'
      if params[:course_id] != ""
        @course_ids = params[:course_id].split(",")
        @course_ids = @course_ids[1,@course_ids.size]
        for id in @course_ids
          @enrollment = Enrollment.new
          @offering = Offering.find(id)
          @enrollment.offering = @offering
          @enrollment.user = current_user
          if @enrollment.save

           # render :partial => "users/other_course_list", collection: current_user.offerings, as: :course, :locals => {:wrapper_class => "wrapper_large"} 
          end
        end
      end
    end
    @user.avatar = nil if params[:delete_avatar] == "1"
    params[:user][:extracurricular_ids] = @user.split_attribute_list(params[:extracurriculars_list], Extracurricular, :extracurricular_ids) if params[:extracurriculars_list].present?
  #  debugger
    if @user.update_attributes(params[:user])
      photo_url_boolean
      school_id_boolean
      sports_boolean
      majors_boolean
      enrollments_boolean
      #majors after update
      @majors_a = @user.major_ids 
      if !(@majors_a.sort == @majors_b.sort)
        #majors that were added, update rankings 
        @added_majors = @majors_a - (@majors_b & @majors_a)
        @added_majors.each do |id|
          Major.find(id).users.where(:school_id => @user.school_id).each do |classmate|
            if @user.id != classmate.id
              Recommendation.connect_new(@user.id, classmate.id, 4)
            end  
          end 
        end
        #majors that were removed, update rankings 
        @removed_majors = @majors_b - (@majors_a & @majors_b)
        @removed_majors.each do |id|
          Major.find(id).users.where(:school_id => @user.school_id).each do |classmate|
            if @user.id != classmate.id
              Recommendation.disconnect_new(@user.id, classmate.id, 4)
            end
          end 
        end
      end
      if @user.majors.blank?
        @action_bar_message = "#{@user.name}"
      else
        @action_bar_message = "#{@user.name} - #{@user.majors.map(&:name).join(",")}"
      end
      flash[:notice] = "Account updated!"
      @success = true
      respond_to do |format|

        format.html { 
          referrer_path = URI(request.referrer).path
          if referrer_path == user_account_path(@user)
            redirect_to custom_user_path(@user.custom_url)
          elsif referrer_path = user_welcome_path(@user)
            current_user.new = false
            current_user.save!
            redirect_to custom_user_path(@user.custom_url, :other => true)
          else
            redirect_to @user 
          end
        }
        format.js {@user.reload}
      end
    else
      if params[:redirect_back] == "profile_wizard"
        render :action => :profile_wizard, :layout => 'plain'
      else
        render :action => :account
      end
    end
  end
  
  def destroy
    @user.destroy
    flash[:notice] = "Account deleted!"
    redirect_to root_path
  end
  
  def account
    if @user != current_user #this is so no user can access another user's welcome page
      redirect_to custom_user_path(current_user.custom_url)
    end
    logger.debug "UsersController#account"
  end
  
  #def autocomplete_course
  #  @search = Sunspot.search Offering do
  #    fulltext params[:keywords]
  #    paginate :page => 1, :per_page => 20
  #  end
  #  result = @search.results.map { |r|
  #    h = {}
  #    h[:type] = "Offering"
  #    h[:label] = r.identifier_name
  #    h[:value] = r.identifier_name
  #    h[:id] = r.id
  #    h
  #  }
  #  render :json => result.to_json
  #end
  
  def profile_wizard
    render :layout => 'plain'
  end
  
  def completion_percentage
  end
  
  def extracurriculars
    if request.xhr?
      json = []
      Extracurricular.search(params[:term]).each do |e|
        json << {id: e.name, label: e.name, value: e.name}
      end
      render :json => json
    else
      redirect_to root_url
    end
  end
  

  # this code was not previously there
  #    <%= link_to "Drop this class", user_drop_class_path(:user_id => current_user.id, :offering_id => @class.id), method: :delete, confirm: "Are you sure?", style: "font-size: 11px;" %>

  def drop_class
    offering = Offering.find params[:offering_id]
    enrollment = @current_user.enrollments.find_by_offering_id offering.id
    offering.posts.create(:user_id => current_user.id, :text => "#{@current_user.name} dropped this class.")
    if enrollment.delete      
      offering.user_ids.each do |id|
        if current_user.id != id
          Recommendation.disconnect_new(current_user.id, id, 2)
        end 
      end
    end
    @course_id = offering.id
    @calendar = Calendar.where(:course_id => offering.id.to_s)
    @calendar.each do |cal|
      cal.update_attributes(:days => 'deleted')
    end
     # if controller == UsersController
     #   redirect_to show_users_path(@current_user)
     # else 
        redirect_to :controller => "home", :action => "index"
     # end
  end

  def welcome
    if @user != current_user #this is so no user can access another user's welcome page
      redirect_to custom_user_path(current_user.custom_url)
    else
      render :layout => 'login'
      @authentication = Authentication.new
      @user = current_user
    end
  end

  def drop_class_in_profile
    offering = Offering.find params[:offering_id]
    enrollment = @current_user.enrollments.find_by_offering_id offering.id
    offering.posts.create(:user_id => current_user.id, :text => "#{@current_user.name} dropped this class.")
    if enrollment.delete      
      offering.user_ids.each do |id|
        if current_user.id != id
          Recommendation.disconnect_new(current_user.id, id, 2)
        end   
      end
    end
    @course_id = offering.id
    @calendar = Calendar.where(:course_id => offering.id.to_s)
    @calendar.each do |cal|
      cal.update_attributes(:days => 'deleted')
    end
        redirect_to "/#{@current_user.custom_url}"
  end

  def create_activity
    @create_array = []
    @user = current_user
    @activities = @user.activity.page(params[:page]).per_page(50)
    current_user.friends.each do |friend|
    @create_array << friend
    end
    @create_array << current_user
    @create_array.each do |user|
    message_body = ActivityRenderer.new.generate_message(user, 'wall_post', :user => current_user, :message => params[:message])
    ActivityMessage.create(:user_id => user.id, :body => message_body, :activist => current_user) 
   # render :partial => 'users/list_item.html.erb', :locals => {:activity_messages => current_user.activity_messages, :user_id => current_user.id}
    end
    respond_to do |format|
      format.js
    end
  end

  def reply_with_activity
    @user = current_user
    @activities = @user.activity.page(params[:page]).per_page(50)
    @sender = current_user
    @old_message = params[:old_message_body]
    message_for_sharing = ActionController::Base.helpers.strip_tags("#{@old_message}")
    @sendee = User.where(:id => params[:sendee_id]).first
    message_body = ActivityRenderer.new.generate_message(@sendee, 'reply_form', :user => current_user, :message => params[:message], :old_message => message_for_sharing)
    if params[:message_type] == "private"
      ActivityMessage.create(:user_id => @sendee.id, :body => message_body, :activist => current_user)
    else
      current_user.friends.each do |friend|
        ActivityMessage.create(:user_id => friend.id, :body => message_body, :activist => current_user)      
      end
    end
    respond_to do |format|
      format.js
    end
  end
  
  def share_activity
    @user = current_user
    @activity_message = ActivityMessage.find(params[:activity_message_id])   
    @create_array = []
    current_user.friends.each do |friend|
    @create_array << friend
    end
   # @create_array << current_user
    message_for_sharing = ActionController::Base.helpers.strip_tags("#{@activity_message.body}")
    @create_array.each do |user|
   # message_body = @activity_message.body
  
    message_for_sharing = ActionController::Base.helpers.strip_tags("#{@activity_message.body}")

    message_body = ActivityRenderer.new.generate_message(user, 'share_again', :user => current_user, :message => message_for_sharing)

    like = @activity_message.like
    original_user = @activity_message.activist
    ActivityMessage.create(:user_id => user.id, :body => message_body, :activist => current_user, :like => like) 
    end
    if !current_user.omniauth_facebook_token.nil?
      current_user.facebook.put_connections("me", "feed", {:message => "#{message_for_sharing}", :link => 'http://www.studyhall.com/'})
    end
    @activities = @user.activity.page(params[:page]).per_page(50)
    respond_to do |format|
      format.js 
    end
  end

  def increase_like
    @user = current_user
    @activity_message = ActivityMessage.find(params[:activity_message_id])
    @messages = ActivityMessage.where(:body => @activity_message.body)
    @messages.each do |message|
      message.like = message.like + 1 
      message.save
      @user.has_likes.create(:user_id => @user.id, :activity_message_id => message.id)
      message.save
    end
    @activities = @user.activity.page(params[:page]).per_page(50)
    respond_to do |format|
      format.js
    end
  end      


  def delete_activity
    @user = current_user
    @activity_message = ActivityMessage.find(params[:activity_message_id])
    @activity_messages = ActivityMessage.where(:body => @activity_message.body)
    @activity_messages.each do |message|
    message.delete
    end 
    @activities = @user.activity.page(params[:page]).per_page(50)
    respond_to do |format|
      format.js
    end
  end 


  def hide_activity 
    @activity_message = ActivityMessage.find(params[:activity_message_id])
    @activity_message.delete
    @user = current_user
    @activities = @user.activity.page(params[:page]).per_page(50)
    respond_to do |format|
      format.js
    end
  end





  
  def add_class
    @offering = Offering.find params[:offering_id]   
    @offering.enrollments.create(:user_id => current_user.id)
    current_user.friends.each do |friend|
      message_body = ActivityRenderer.new.generate_message(friend, 'course_add', :user => current_user, :offering => @offering)
      ActivityMessage.create(:user_id => friend.id, :body => message_body, :activist => current_user)
    end
    redirect_to "/classes/#{@offering.slug}"
  #  if current_user.new
  #    redirect_to ('/users/' + current_user.id.to_s + '/welcome')
  #  else
  #    redirect_to "/classes/#{@offering.slug}"
  #  end


  end
  #possibly add these to add_class
  #  respond_to do |format|
  #    format.html {redirect_to "/classes/#{@offering.slug}"}
  #    format.js {render :layout => false}
  #  end
  #@course_id = offering.id
  #@calendar = Calendar.where(:course_id => offering.id.to_s)
  #@calendar.each do |cal|
  # cal.update_attributes(:days => 'added')
  #end


  
  #Different ajax action for sropping class on searches page
  def drop_class_searches
    @offering = Offering.find params[:offering_id]
    enrollment = @current_user.enrollments.find_by_offering_id @offering.id
    @offering.posts.create(:user_id => current_user.id, :text => "#{@current_user.name} dropped this class.")
    if enrollment.delete      
      offering.user_ids.each do |id|
        if current_user.id != id
          Recommendation.disconnect_new(current_user.id, id, 2)
        end   
      end
    end
    
      
    @calendar = Calendar.where(:course_id => @offering.id.to_s)
    @calendar.each do |cal|
      cal.update_attributes(:days => 'deleted')
    end
    respond_to do |format|
      format.html {redirect_to "/home"}
      format.js {render :layout => false}
    end
  end
  
  def add_major
    unless Major.find_by_name(params[:major][:title])
      @major = Major.create(:name => params[:major][:title], :school => current_user.school)
      render :text => @major.id
    else
      render :text => ''
    end
  end
  
  def add_sport
    unless Sport.find_by_name(params[:sport][:title])
      @sport = Sport.create(:name => params[:sport][:title], :school => current_user.school)
      render :text => @sport.id
    else
      render :text => ''
    end
  end

  def block
    store_location
    blocked_user = User.find params[:blocked_user_id]
    current_user.block!(blocked_user)
    redirect_to request.referer
  end

  def photo_url_boolean
    if @user.photo_url.blank? 
      @user.photo_url_boolean = false
      puts "why are we not in arlington virginia hoogie boogie hoogie boogie" 
      @user.save
      puts "where is tita?" 
    else
      @user.photo_url_boolean = true
      puts "where is tita and ross?" 
      @user.save
      puts "where is tita and ross and ben?" 
    end
  end


  def school_id_boolean
    if @user.school_id.blank? 
      puts "creecher and todd" 
      @user.school_id_boolean = false
      puts "big bad barry sotero" 
      @user.save
    else
      @user.school_id_boolean = true
      puts "why are we not in arlington virginia" 
      @user.save
    end
  end


  def majors_boolean
    if @user.majors.blank? 
      @user.majors_boolean = false
      puts "take me to hoogie boogie land curtis brumbalow" 
      @user.save
      puts "we will not abandon the revolution"
    else
      puts "what is our core set of values"
      @user.majors_boolean = true
      puts "take me to hoogie boogie land curtis brumbalow and pete and mark" 
      @user.save
    end
  end

  def enrollments_boolean
    if @user.enrollments.blank? 
      puts "take me to hoogie boogie land" 
      @user.enrollments_boolean = false
      @user.save
      puts "life is always great"
    else
      @user.enrollments_boolean = true
      puts  "sparky"
      @user.save 
      puts "hot as hell"
    end
  end

  def sports_boolean
    if @user.sports.blank? 
      puts "take me to hoogie boogie land bro" 
      @user.sports_boolean = false
      puts "lets improvise dude" 
      @user.save
      puts "take me to hoogie boogie land sparky sparky sparky" 
    else
      @user.sports_boolean = true
      @user.save
    end
  end

  
  protected
  def redirect_to_user
    redirect_to @user
  end
  
  private
  def fetch_user
    if params[:id] =~ /^\d+$/
      @user =  User.find(params[:id])
      redirect_to profile_path(@user.custom_url, :mode => params[:mode]) if @user && action_name == "show"
    elsif params[:user_id]
      @user =  User.find(params[:user_id])
    else # (was: elsif params[:id] =~ /^[a-z0-9]+$/)
      @user = User.find_by_custom_url(params[:id])
    end
  end
  
  def require_no_user_or_admin
    require_admin if current_user
  end
  
  def check_first_last_name
    unless (current_user.first_name.blank? && current_user.last_name.blank?)
      redirect_to user_path(current_user)
    end
  end

  
  def check_tour_mode
    if request.referrer.include?('tour')
      @tour = true
      @rel_form = params[:rel_form]
      forms = ['affiliations_form', 'invitations_form']
      index = forms.index(@rel_form)
      @next_form = forms[index + 1]
    end
  end

  def check_other_mode
    if request.referrer.include?('other')
      @other = true
      @other_form = params[:other_form]
      forms = ['name_form', 'affiliations_form', 'photo_form','invitations_form']
      index = forms.index(@other_form)
      @next_form = forms[index + 1]
    end
  end


  def check_completion_mode
    if request.referrer.include?('completion')
      @completion = true
      @com_form = params[:com_form]
      if current_user.next_blank_form_finder == 4
        @next_form = 'photo_form'
      else 
        @next_form = 'invitations_form'
      end
    end
  end






end
