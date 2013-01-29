
class QuestionsController < ApplicationController
  
def index
    # get matching user
    # if user, look for that user's questions, else all quiestions for that class
    # then looks for questions with those question params 
    # TODO refactor
    # @users, @users_with_extras = [], []
    # @users = User.where(params[:user]) if params[:user]
    # @users_with_extras = User.has_extracurricular(params[:extracurricular_id].first.to_i) if params[:extracurricular_id]
    # @users = @users.concat(@users_with_extras)
    # @users = User.where(params[:user])
    if params[:user]
      sport_id = params[:user].delete(:sport_id)
      frat_sorority_id = params[:user].delete(:frat_sorority_id)
      @users = User.where(params[:user])
      @users = @users.has_sports([sport_id]) if sport_id
      @users = @users.has_frat_sororities([frat_sorority_id]) if frat_sorority_id
    end
    
    @class = Offering.find params[:class_id]
    @questions = []
    #if @users
    #  @users.each do |user|
    #    @questions << Question.for_offering(@class).by_user(user).where(params[:question]).recent.top_level
    #  end
    #else
    #  @questions = Question.where(params[:question]).recent.top_level
    #end
    @questions = find_questions
    render :partial => 'questions/list_item.html.erb', :locals => {:questions => @questions.flatten}
  end
  
  def new
    @question = Question.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group_question }
    end
  end
  
  def create
    @question_type = params[:question_type]
    @class = Offering.find params[:class_id]
    @question = Question.new
    @question.user_id = current_user.id
    @question.text = params[:message]
    #previously not there
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
      #if request.xhr?
    #  render_questions
      #end
      #push_broadcast :class_question, :class_id => @question.offering_id, :name => @question.offering.course.title
      if request.xhr?
        render_questions
      end
    end
    push_broadcast(:question_asked, :offering_id => @class.id)
    @class.users.each do |user|    
      Notifier.new_question(@question, user).deliver
    end
  end
  
  def update
    @question = Question.find(params[:id])
    if @question.update_attributes params[:question]
      Notifier.report_question(current_user, @questions).deliver if params[:reported]
      if request.xhr?
        render_questions
      end
    end
  end
  
  def filter
    @modal_link_id = params[:link_id]
    @class = Offering.find params[:class_id], :include => :questions
    respond_to do |format|
      format.js
    end
  end

  def view_question
    @class = Offering.find(params[:offering_id])
    @questions = []
    @class.questions.recent.each do |question|
      if question.flagged_as == 'question'
        @questions << question
      end
    end
      if request.xhr?
        render :partial => 'questions/list_item', :locals => {:questions => @questions, :class_id => params[:offering_id], :question_type => 'class'}
      end
  end

  def view_comment
    @class = Offering.find(params[:offering_id])
    @questions = []
    @class.questions.recent.each do |question|
      if question.flagged_as == 'posting'
        @questions << question
      end
    end
      if request.xhr?
        render :partial => 'questions/list_item', :locals => {:questions => @questions, :class_id => params[:offering_id], :question_type => 'class'}
      end
  end

  def view_all
    @class = Offering.find(params[:offering_id])
    @questions = []
    @class.questions.recent.each do |question|
        @questions << question
    end
      if request.xhr?
        render :partial => 'questions/list_item', :locals => {:questions => @questions, :class_id => params[:offering_id], :question_type => 'class'}
      end
  end  



  
  private
  
  def render_questions
    if @question_type == 'group'
      @questions = Group.find(params[:class_id]).questions.where("question_type <= ?", 'group').recent.top_level
    else
      @offering = Offering.find(params[:class_id])
      @questions = Offering.find(params[:class_id]).questions.recent.top_level
    end
    render :partial => 'questions/list_item', :locals => {:questions => @questions, :class_id => params[:class_id], :question_type => params[:question_type]}
  end

  def find_questions
    #@class = Offering.find params[:class_id]
    if params[:filter]
      @filtered_results = true
      flash.now[:action_bar_message] = "Filtered questions "
      @questions = Question.filter(params[:filter], @class).recent.top_level
    else
      @filtered_results = false
      @questions = @class.questions.recent.top_level
    end
    @questions
  end

end
