class SearchesController < ApplicationController
  before_filter :set_action_bar, :only => [:show]

  def create
    if params[:keywords].present?
      @search = current_user.searches.create!(keywords:params[:keywords], :user_id => current_user.id)
      redirect_to @search
    elsif params[:search][:keywords].present?
      @search = current_user.searches.create!(params[:search])
      redirect_to @search
    else
      redirect_to :back
    end
  end
  
  def show
    @search = Search.find_by_id(params[:id])
    @search = Search.new if @search.nil?
    if @search.any?
      flash[:action_bar_message] = "Search Results for '#{@search.keywords}'"
    else
      flash[:action_bar_message] = "No Results for '#{@search.keywords}'"
    end
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end
  
  include ActionView::Helpers::TextHelper
  
  def sort
    @type = params[:type]
    @keywords = params[:keywords]
    if @type == "note"
      @field = params[:n_options]
      sort_notes
    elsif @type == "course"
      @field = params[:c_options]
      sort_courses
    elsif @type == "user"
      @field = params[:u_options]
      sort_users
    elsif @type == "group"
      @field = params[:g_options]
      sort_groups
    end
    debugger
    respond_to do |format|
      format.html {render @type}
      format.js 
    end
    @id = params[:id]
  end 
  def sort_users
    if @field == "name"
      debugger
      @search = User.search do 
        fulltext params[:keywords]
        with :active, true
        order_by :last_name, :asc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "school"
      debugger
      @search = User.search do 
        fulltext params[:keywords]
        with :active, true
        order_by :school_name, :asc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "major"
      debugger
      @search = User.search do 
        fulltext params[:keywords]
        with :active, true
        order_by :major, :asc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "year"
      debugger
      @search = User.search do 
        fulltext params[:keywords]
        with :active, true
        order_by :grad_year, :desc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "rating"
      debugger
      @search = User.search do 
        fulltext params[:keywords]
        with :active, true
        order_by :plusminus, :desc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    else
      @field = "BAD"
    end
    @search
  end
  def sort_notes
    if @field == "name"
      @search = Note.search do 
        fulltext params[:keywords]
        order_by :name, :asc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "created"
      @search = Note.search do 
        fulltext params[:keywords]
        order_by :created_at, :desc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "owner"
      @search = Note.search do 
        fulltext params[:keywords]
        order_by :owner_name, :desc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    elsif @field == "course"
      @search = Note.search do 
        fulltext params[:keywords]
        order_by :course_name, :asc
        paginate :page => params[:page], :per_page => APP_CONFIG['per_page']
      end
    else
      @field = "BAD"
    end
    @search
  end
  def sort_groups
    if @field == "name"
      @search = Group.search do 
        fulltext params[:keywords]
        order_by :group_name, :asc
        paginate :page => params[:page], :per_page => 5
      end
    elsif @field == "owner"
      @search = Group.search do 
        fulltext params[:keywords]
        order_by :owner_name, :desc
        paginate :page => params[:page], :per_page => 5
      end
    elsif @field == "count"
      @search = Group.search do 
        fulltext params[:keywords]
        order_by :member_count, :asc
        paginate :page => params[:page], :per_page => 5
      end
    else
      @field = "BAD"
    end
    @search
  end
  def sort_courses
    if @field == "title"
      @search = Course.search do 
        fulltext params[:keywords]
        order_by :title, :asc
        paginate :page => params[:page], :per_page => 5
      end
    elsif @field == "dept"
      @search = Course.search do 
        fulltext params[:keywords]
        order_by :department, :asc
        paginate :page => params[:page], :per_page => 5
      end
    else
      @field = "BAD"
    end
    @search
  end
  
  def autocomplete
    @search = Sunspot.search Course, User do
      fulltext params[:keywords]
      paginate :page => 1, :per_page => 5
    end
    result1 = @search.results.map { |r| 
      h = {}
      case r.class.name
      when 'Course'
        h[:type] = "Course"
        h[:label] = truncate(r.title, :length => 30)
        h[:value] = r.title
        h[:url] = "/searches/direct/" + r.title
      when 'User'
        h[:type] = "User"
        h[:label] = truncate(r.name, :length => 30)
        h[:value] = r.name
        h[:url] = "/searches/direct/" + r.name
      end
      h
    }
    render :json => result1.to_json
  end
end
