class StudySessionsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper
  before_filter :require_user
  before_filter :set_action_bar, except: [:show]
  before_filter :augment_study_session_params, only: [:create, :update]
  
  def accept_invitation
    @study_session = StudySession.where("invitation_token = ?", params[:invitation_token]).first
    if @study_session
      @inviter = @study_session.user
      if @inviter.friend_with?current_user
        @session_invite = @study_session.session_invites.new()
        @session_invite.study_session_id = @study_session.id
        @session_invite.user_id = current_user.id
        @session_invite.save
        redirect_to :controller => 'study_sessions', :action => 'show', :id => @study_session.id
      else
        flash[:notice] = "In order to access this session, you must be buddies with the person who sent the invite."
        redirect_to :controller => "study_sessions", :action => "index"
      end
    else
      flash[:notice] = "Invalid invite token for study session - are you sure you have the correct url?"
      redirect_to :controller => "study_sessions", :action => "index"
    end
  end
  def index
    @study_sessions = find_study_sessions
    @study_sessions.each do |study_session|
      study_session.session_files.build
    end
    @index = true
  end
  
  def show
    if !(defined? session[:ep_sessions])
      session[:ep_sessions] = {}    
    end
    @study_session = StudySession.find(params[:id])
    @session_file = @study_session.prepare_session(current_user)
    raise User::NotAuthorized unless @study_session.joinable_by?(current_user)
    @token = @study_session.generate_token(current_user)
    @show = true
   # ether = EtherpadLite.connect(APP_CONFIG["etherpad"]["host"], APP_CONFIG["etherpad"]["api_key"])
    ether = EtherpadLite.connect('http://0.0.0.0:9001', 'vSnRxGvcZCOKENy52ETG4HP3PDZtYHkF')
    # Get the EtherpadLite Group and Pad by id
    @etherpad_group = ether.group(@study_session.id)
    @pad = @etherpad_group.get_pad(@study_session.id)
    if @study_session.users.find(current_user)
      author = ether.author("my_app_user_#{current_user.id}", :name => current_user.name)
        # Get or create an hour-long session for this Author in this Group
      if session[:ep_sessions][@etherpad_group.id] == nil
        sess = @etherpad_group.create_session(author, 60)
      else
        sess = ether.get_session(session[:ep_sessions][@etherpad_group.id])
      end 
      if sess.expired?
        sess.delete
        sess = @etherpad_group.create_session(author, 60)
      end
      session[:ep_sessions][@etherpad_group.id] = sess.id
        # Set the EtherpadLite session cookie. This will automatically be picked up by the jQuery plugin's iframe.
      #cookies[:sessionID] = {:value => sess.id, :domain => ".studyhall.com"}
      cookies[:sessionID] = {:value => sess.id}
    end
  end
  
  def new
    @modal_link_id = params[:link_id]
    @study_session = StudySession.new
    @study_session.buddy_ids = [params[:id]]
    @study_session.session_files.build
    respond_to do |format|
      if params[:calendar]
        format.js {render "calendar"}
      else
        format.js
      end
    end
  end
  
  def create
    @study_session = StudySession.new
    @study_session.name = params[:study_session][:name]
    @study_session.user_id = current_user.id
    @study_session.offering_id = params[:study_session][:offering_id]
    @study_session.name = params[:study_session][:name]
    @study_session.time_start = params[:study_session][:time_start]
    @study_session.time_end = params[:study_session][:time_end]
    @study_session.calendar = true
    @study_session.buddy_ids = params[:study_session][:buddy_ids]
    @study_session.sender_id = current_user.id
   # @study_session.init_opentok
    @study_session.invitation_token = Digest::SHA1.hexdigest([Time.now, rand].join)
    buddyids = params[:study_session][:buddy_ids]
    buddyids.shift
    buddyids_w_current = [current_user.id.to_s] + buddyids
    generate_invite_message
    debugger
    if @study_session.calendar?
      @study_session.addtocalendar
      if @study_session.save
        generate_invite_message
      #  ether = EtherpadLite.connect(APP_CONFIG["etherpad"]["host"], APP_CONFIG["etherpad"]["api_key"])
        ether = EtherpadLite.connect('http://0.0.0.0:9001', 'vSnRxGvcZCOKENy52ETG4HP3PDZtYHkF')
        @etherpad_group = ether.create_group({:mapper => @study_session.id})
        @pad = @etherpad_group.create_pad(@study_session.id, {:text => ' '})
        @local_cal = current_user.calendars.new
        @local_cal.update_attributes({ :date_start => @study_session.time_start, :time_start => @study_session.time_end, :schedule_id => @study_session.id })
        redirect_to calendars_url, :notice => "Study session '#{@study_session.name}' scheduled successfully for #{@study_session.time_start} at #{@study_session.time_end}."
      else
        render action: 'new'
      end
    elsif @study_session.save
      generate_invite_message
     # ether = EtherpadLite.connect(APP_CONFIG["etherpad"]["host"], APP_CONFIG["etherpad"]["api_key"])
      ether = EtherpadLite.connect('http://0.0.0.0:9001', 'vSnRxGvcZCOKENy52ETG4HP3PDZtYHkF')
      @etherpad_group = ether.create_group({:mapper => @study_session.id})
      @pad = @etherpad_group.create_pad(@study_session.id, {:text => ' '})
      redirect_to @study_session
    else
      render action: 'new'
    end
  end
  
  def direct
    @study_session = StudySession.new
    if !params[:note_id].nil?
      @note = Note.find( params[:note_id])
      @study_session.name = @note_name
      @note_content = @note.content
    else
      @study_session.name = "Untitled"
      @note_content = ' '
    end
    @study_session.user_id = current_user.id
   # @study_session.init_opentok
    @study_session.shareable = true
    @study_session.sender_id = current_user.id
    @study_session.invitation_token = Digest::SHA1.hexdigest([Time.now, rand].join)
    if @study_session.save
    #Connect to etherpadlite instance - please see http://jordanhollinger.com/docs/ruby-etherpad-lite/ for detailed documentation
        ether = EtherpadLite.connect('http://0.0.0.0:9001', 'vSnRxGvcZCOKENy52ETG4HP3PDZtYHkF')
    #  ether = EtherpadLite.connect(APP_CONFIG["etherpad"]["host"], 'OazTir1zGBZmR3D5AhIUv4d6e8zvIqKx')
      #Create etherpad group
      @etherpad_group = ether.create_group({:mapper => @study_session.id})
      @pad = @etherpad_group.create_pad(@study_session.id, {:text => ' '})
      @pad.html = "<div>" + @note_content + "</div>"
      redirect_to @study_session
    end
  end

  def update
    @study_session = current_user.study_sessions.find(params[:id])
    @study_session.update_attributes(params[:study_session])
    if params[:source] == "show_view"
      redirect_to @study_session
    else
      redirect_to study_sessions_path
    end
  end
  
  def destroy
    @study_session.destroy(params[:id])
    redirect_to study_sessions_path
  end
  
  private
  
  def find_study_sessions
    if params[:filter]
      @filtered_results = true
      flash.now[:action_bar_message] = "Filtered StudyHalls "
      study_sessions = StudySession.filter(params[:filter], current_user)
    else
      @filtered_results = false
      study_sessions = current_user.study_sessions
    end
    study_sessions
  end

  def augment_study_session_params
    params[:study_session] ||= {}
    params[:study_session][:remote_addr] = request.remote_addr
    params[:study_session][:user_id] = current_user.id
  end

  def generate_invite_message
    study_session = @study_session
    @study_session.message = render_to_string :partial => "message", :locals => {:study_session => study_session, sender: current_user}
  end

end

