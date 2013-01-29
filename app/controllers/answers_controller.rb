
class AnswersController < ApplicationController
  before_filter :require_user

  def create
   # @question = Question.find(params[:parent_id])
    @class = Offering.find params[:class_id]
    @question_type = params[:question_type]
    @answer = Answer.new(params[:answer])
    @question = Question.where(:id => params[:question_id]).first
  #  @question = 
    if @answer_type == 'group'
      @answer.group_id = params[:group_id]
    else
      @answer.offering_id = params[:class_id]
    end
    @answer.user = current_user
    if @answer.save
      if request.xhr?
        render_questions
      end
   Notifier.new_answer(@answer, @answer.user, @question.user, @question).deliver
      if @question.has_answers?
        @question.answers.each do |previous_answer|
          Notifier.new_answer(previous_answer, previous_answer.user, @question.user, @question).deliver        
        end
      end
    end
#    push_broadcast(:question_asked, :offering_id => @class.id)  
    uri = URI.parse(APP_CONFIG["faye"])
    options = {:offering_id => @answer.offering_id, :sender => @answer.user, :receiver => @question.user, :offering => @question.offering}
    message = "#{@answer.user.title_name} answered your question."
    data = {:user_id => @question.user.id, :offering_id => @answer.offering_id, :message => message, :intent => "question_answered", :current => true, :args => options}
    serialized_data = data.to_json
    notification = {:channel => "/broadcasts/user/#{@question.user.id}", :data => serialized_data}
    Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)
    if @question.has_answers?
      # Welles, I don't like the sound of silence 
      @question.answers.each do |previous_answer|
      #but I do prefer Mrs. Robinson,
        options = {:offering_id => @answer.offering_id, :sender => @answer.user, :receiver => previous_answer.user, :offering => @question.offering}
        #Jesus loves you more than you should know
        message = "#{@answer.user.title_name} answered your question."
        #God bless you please, Mrs. Robinson
        data = {:user_id => previous_answer.user.id, :offering_id => @answer.offering_id, :message => message, :intent => "question_answered", :current => true, :args => options}
        #we'd like to help you learn, help yourself
        serialized_data = data.to_json
        #look around you, all you see is sympathetic lies
        notification = {:channel => "/broadcasts/user/#{previous_answer.user.id}", :data => serialized_data}
        #Jesus loves you more than you should know
        Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)
        #heaven holds a place for those who pray
        #it's a little secret, just the Robinsons are there
        #coo coo ca choo, mrs. robinson
        #God bless you please, mrs. robinson
      end
    end  
  end

  def update
    @answer = Answer.find(params[:id])
    if @answer.update_attributes params[:answer]
      Notifier.report_answer(current_user, @answer).deliver if params[:reported]
      if request.xhr?
        render_questions
      end
    end
  end

  private
  
  def render_questions
    if @question_type == 'group'
      @questions = Group.find(params[:group_id]).questions.where("question_type <= ?", 'group').recent.top_level
    else
      @questions = Offering.find(params[:class_id]).questions.recent.top_level
      @offering = Offering.find(params[:class_id])
    end

    render :partial => '/questions/list_item', :locals => {:questions => @questions, :class_id => params[:class_id], :question_type => 'class'}

  end

end
