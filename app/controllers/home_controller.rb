class HomeController < ApplicationController

  before_filter :require_user, only: [:index]


#  caches_page :landing_page

  
  def index
    if !(defined? session[:ep_sessions])
      session[:ep_sessions] = {}    
    end
    @enrollment = Enrollment.new
    @user = @current_user
    @activities = current_user.activity.page(params[:page]).per_page(5)
    @news_feed = current_user.school.rss_entries.order('created_at DESC').page(params[:page]).per_page(5)
    puts "#{params[:page]}"
    unless current_user.profile_complete?
      flash.now[:notice] = "Your profile is #{current_user.profile_completion_percentage}% complete!"
    end
    check_tour_mode
    respond_to do |format|
      format.html
      format.js
    end
  end

  def ping
    Rails.cache.fetch('ping') do
      @ping = RssEntry.first
    end
  end

  def landing_page
    @user_session = UserSession.new
    @signup = Signup.new
    render layout: "landing"
  end

  protected
    
    def check_tour_mode
      @tour = true if params[:tour] == 'true'
    end
end
