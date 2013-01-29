class SessionInvitesController < ApplicationController

  before_filter :require_user
  before_filter :find_study_session

  def new
   # @session_invite = @study_session.session_invites.new(sender_id: current_user.id)
   @session_invite = @study_session.session_invites.new
  end

  def create
    #generate facebook messages
  #  current_user.share_studyhall(params[:session_invite][:user_id])
   # current_user.share_studyhall(params[:user_id])
    puts "here is the original sam code"
    puts "#{params[:session_invite][:user_id]}"
    puts "this is probably better"
    puts "#{params[:user_id]}" 
    puts "rocket queen says this will work"
  #  puts "#{(params[:session_invite][:user_id]).to_a}"
  #  puts "is this right"
  #  puts "#{(params[:session_invite][:user_id]).to_s}"
    puts "finally, the array"
    puts "#{((params[:session_invite][:user_id]).to_s).lines.to_a}"    
    current_user.share_studyhall(((params[:session_invite][:user_id]).to_s).lines.to_a)
    Rails.logger.info("\n\n\n\n\n\n#{params[:session_invite][:user_id]}\n\n\n\n\n\n")
    @session_invite = @study_session.session_invites.new(params[:session_invite])
    @session_invite.sender_id = params[:user_id] 
    generate_invite_message
    if @session_invite.save
      message_body = ActivityRenderer.new.generate_message(@session_invite.user, 'studyhall_invite', :inviter => current_user, :studyhall => @session_invite.study_session)
      ActivityMessage.create(:user_id => @session_invite.user.id, :body => message_body, :activist => current_user)
      uri = URI.parse(APP_CONFIG["faye"])
      options = {:study_session_id => @study_session.id, :sender => current_user, :receiver => @session_invite.user, :study_session => @study_session}
      message = "#{current_user.title_name} has invited you to a study session."
      data = {:user_id => @session_invite.user.id, :study_session_id => @study_session.id, :message => message, :intent => "study_session_invite", :current => true, :args => options}
      serialized_data = data.to_json
      notification = {:channel => "/broadcasts/user/#{@session_invite.user.id}", :data => serialized_data}
      Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)
      respond_to do |format|
        format.js
        format.html
      end
    end
  end

  private

  def find_study_session
    @study_session = current_user.study_sessions.find(params[:study_session_id])
  end

  def generate_invite_message
    studyhall = @session_invite.study_session
    @session_invite.message = render_to_string :partial => "message", :locals => {:studyhall => studyhall, sender: @session_invite.user}
  end

end
