class FriendshipsController < ApplicationController
  
  before_filter :require_user

    def index #this lists all the friends
      @friends = current_user.friends
    end

    def new #this defines the users that the current_user can friend
      @users = User.all :conditions => ["id != ?", current_user.id]
    end

    def create #this sends a friendship invitations
      @invitee = User.find_by_id(params[:user_id])
      @inviter = current_user
      if current_user.invite @invitee
        push_broadcast :friend_request, :inviter_id => @inviter.id, :invitee_id => @invitee.id #this calls the method in application_controller
        if params[:rec].blank?
          respond_to do |format|
            format.html {redirect_to user_path}
            format.js
          end
        else
          render :nothing => true
        end
        #redirect_to new_friend_path, :notice => "Successfully invited friend!"
      else
        redirect_to new_friend_path, :notice => "Sorry! You can't invite that user!"
      end
    end

    def update #this creates the actual friendship when the invitee accepts
      @inviter = User.find_by_id(params[:id])
      @invitee = current_user
      if current_user.approve @inviter
        @inviter.friends.each do |friend|
          message_body = ActivityRenderer.new.generate_message(friend, 'friend_wall_post', :user => @inviter, :friend => friend)
          ActivityMessage.create(:user_id => friend.id, :body => message_body, :activist => @inviter) 
        end

        @invitee.friends.each do |friend|
          message_body = ActivityRenderer.new.generate_message(friend, 'friend_wall_post', :user => @invitee, :friend => friend)
          ActivityMessage.create(:user_id => friend.id, :body => message_body, :activist => @invitee) 
        end
     
        push_broadcast :friend_accept, :inviter_id => @inviter.id, :invitee1_id => @invitee.id
        respond_to do |format|
          format.html {redirect_to user_path}
          format.js
        end
        Recommendation.fconnect_new(current_user.id, @inviter.id, 1) 
        #redirect_to new_friend_path, :notice => "Successfully confirmed friend!"
      elsif current_user.remove_friendship inviter
        redirect_to home_index_path, :notice => "Request denied successfully"
      end
    end

    def requests #this lists the outstanding friend invitations for the current_user
      @pending_requests = current_user.pending_invited_by
    end

    def invites #this lists the outstanding friend invitations by the current_user
      @pending_invites = current_user.pending_invited
    end

    def destroy #this removes a friend or rejects a friend request
      user = User.find_by_id(params[:id])
      if current_user.remove_friendship user
        Recommendation.fdisconnect_new(current_user.id, user.id, 1) 
        redirect_to home_index_path, :notice => "Successfully removed friend!"
      else
        redirect_to @user, :notice => "Sorry, couldn't remove friend!"
      end
    end 

end
