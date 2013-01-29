class GroupsController < ApplicationController

  before_filter :require_user
  before_filter :set_action_bar

  # GET /groups
  # GET /groups.json
  def index
    @group = Group.new 
    @groups = current_user.groups.page(params[:page] || 1).per_page(5)
    respond_to do |format|
      format.html # show.html.erb
      format.js
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = Group.find(params[:id])
    @member_requests = @group.unanswered_member_requests
    @posts = @group.posts.where("post_type <= ?", 'group').recent.top_level
    @appropriate_group_permissions = GroupPermission.where(:group_id => @group.id)
    @shared_notes = []
    @appropriate_group_permissions.each do |note|
      @shared_notes << Note.where(:id => note.note_id).first
      end




   # @documents = Array.new
   # types = CSV.read("db/doc_types.csv").unshift ["All", "0"]
   # types.each do |type|
   #   @documents << NoteItem.init_set(Backpack.new(@group).contents(page: params[:page], filter: params[:filter], doc_type: type[1]))
   # end



  #  these lines causes major bugs upon redirecting to the homepage
  #  flash[:imitate] = true
  #  flash[:imitates] = "groups-show users-show"


    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])
    @group.members << current_user
    @group.admins << current_user

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:group][:update_group_id])
    @group.avatar = nil if params[:delete_avatar] == "1"
    logger.info("yup#{params[:group]}");
    if @group.update_attributes(params[:group])
      logger.info("huh!");
      flash[:notice] = "Account updated!"
      @success = true
      respond_to do |format|
        format.html { redirect_to @group }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end
  def add_members
    @group = Group.find(params[:id])
    if !@group.member?(current_user)
      @group.members << current_user
      @group.members.each do |member|
       # if member.id != current_user.id
       #   Recommendation.connect_new(current_user.id, member.id, 2)
       # end 
      end 
      redirect_to @group
    else 
      redirect_to @group
    end
  end
  def delete_member
    @group = Group.find(params[:id])
    @group.member_ids.each do |id|
      if id != current_user.id
        Recommendation.disconnect_new(current_user.id, id, 2)
      end 
    end
    @group.members = @group.members.drop(current_user.id)
    redirect_to "/home"
  end
  def delete_group
    @group = Group.find(params[:id])
    @group.delete
    redirect_to "/home"
  end
end
