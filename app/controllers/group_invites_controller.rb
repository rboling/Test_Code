class GroupInvitesController < ApplicationController

  before_filter :require_user
  before_filter :find_group

  def new
    @group_invite = @group.group_invites.new(sender_id: current_user.id)
  end

  def create
    @group_invite = @group.group_invites.new(params[:group_invite])
    generate_invite_message
    @group_invite.save
    
    uri = URI.parse(APP_CONFIG["faye"])
    options = {:group_id => @group.id, :sender => User.find_by_id(current_user.id), :receiver => @group_invite.user, :group => @group}
    message = "#{current_user.title_name} has invited you to join a group."
    data = {:user_id => @group_invite.user.id, :group_id => @group.id, :message => message, :intent => "group_invite", :current => true, :args => options}
    serialized_data = data.to_json
    notification = {:channel => "/broadcasts/user/#{@group_invite.user.id}", :data => serialized_data}
    Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def find_group
    @group = current_user.groups.find(params[:group_id])
  end

  def generate_invite_message
    group = @group_invite.group
    @group_invite.message = render_to_string :partial => "message", :locals => {:group => group, sender: current_user}
  end

end
