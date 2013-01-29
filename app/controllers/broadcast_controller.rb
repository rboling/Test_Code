class BroadcastController < ApplicationController

  def index
    @broadcasts = current_user.current_broadcasts
    @link_id = "notifications_link_id"
    respond_to do |format|
      format.js
      format.json {render @broadcasts}
    end
  end

  def hide_broadcast
   # @broadcast = Broadcast.find(params[:broadcast_id])
    @broadcast = current_user.current_broadcasts.where(:id => params[:broadcast_id]).first
    @broadcast.current = false
    @broadcast.save
    @broadcast.delete
    @user_broadcasts = current_user.current_broadcasts
    @link_id = "notifications_link_id"
    #puts "#{@user_broadcasts.all}"
    respond_to do |format|
      format.js
      format.json {render @user_broadcasts}
    end
  end
  
  def edit
    @broadcast = Broadcast.find(params[:id])
    @broadcast.current = false
    @broadcast.save
    if @broadcast.note_id != nil
      redirect_to note_path(:id => @broadcast.note_id)
    elsif @broadcast.offering_id != nil
      @offering = Offering.where(:id => @broadcast.offering_id).first
      redirect_to "/classes/#{@offering.slug}"
    elsif @broadcast.group_id != nil
      redirect_to "/groups/#{@broadcast.group_id}/add_members/#{@broadcast.group_id}"
    elsif @broadcast.study_session_id != nil
      redirect_to study_session_path(:id => @broadcast.study_session_id)
    else
      redirect_to @broadcast.link
    end
  end

end
