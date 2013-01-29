class GmailInvitesController < ApplicationController
  
  def create
    @gmail_invite = GmailInvite.new(params[:gmail_invite])
    if @gmail_invite.find_friends
      @success = true
      @html = render_to_string partial: "invite_form"
    else
      @success = false
      @html = render_to_string partial: "retrieve_contacts_form"
    end
    respond_to do |format|
      format.js
    end
  end

  def update
    @gmail_invite = GmailInvite.new(params[:gmail_invite])
    if @gmail_invite.send_invites(current_user.full_name)
      @success = true
      @html = render_to_string partial: "success_modal"
    else
      @success = false
      @html = render_to_string partial: "invite_form"
    end
    respond_to do |format|
      format.js
    end
  end

end
