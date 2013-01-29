class NotesController < ApplicationController
  
  layout "full_width"
  
  before_filter :require_user
  before_filter :find_note, except: [:index, :request_access]
  before_filter :set_action_bar
  before_filter :find_notebook
  before_filter :find_folder
  
  def index
    @folders = NoteItem.init_set(current_user.folders)
    if @notebook
      @note_items = NoteItem.init_set(@notebook.notes)
    else
      unless @folder
        @folder = current_user.folders.first
      end
      @note_items = NoteItem.init_set(@folder.notes)
      @documents = Array.new
      types = CSV.read("db/doc_types.csv").unshift ["All", "0"]
      types.each do |type|
        @documents << NoteItem.init_set(Backpack.new(current_user).contents(page: params[:page], filter: params[:filter], doc_type: type[1], folder: @folder.id))
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notes }
    end
  end

  def show
    if !@note.new_record? and current_user.can_edit?(@note)
      redirect_to :action => "edit"
    else
    respond_to do |format|
      format.html {
        redirect_to notes_path, alert: "The Note you try to visit is not allowed to view or not exist!"  and return if @note.new_record?
      }
      format.json { render json: @note }
    end
    end
  end

  def new
    @note = @notebook ? @notebook.notes.build : Note.new
    @group = params[:group]
    @modal_link_id = params[:link_id]
    @remote = false
    respond_to do |format|
      format.html { render "edit" }
      format.json { render json: @note }
      if params[:upload]
        format.js {render "upload"}
      else
        format.js
      end
    end
  end

  def edit
    if(params[:id])
      @note = current_user.permissions.find_by_note_id(params[:id]).permission_setting.note
      if params[:upload]
        @note = params[:upload]
      end
      @modal_link_id = params[:link_id]
      @remote = params[:source].present?
      respond_to do |format|
        format.js
        format.html
      end
    else
      @file = params[:upload][:file]
      @note = UploadUtils::upload(@file, current_user)
      respond_to do |format|
        format.html
        format.json { render json: @note }
      end
    end
  end

  def create
    Rails.logger.info("Notes > 5 mb? #{current_user.notes_too_big}\n\n**********************")
    @note = current_user.notes.new(params[:note])
    @note.creator = current_user.name
    if @note.upload == "true"
      @note = UploadUtils::upload(@note)
      respond_to do |format|
        if @note.save
          if @note.doc_preserved
            format.html { redirect_to notes_path, notice: 'Note was successfully created.' }
          else
            format.html { redirect_to @note, notice: 'Note was successfully created.' }
          end
          format.json { render json: @note, status: :created, location: @note }
        else
          format.html { render action: :edit }
          format.json { render json: @note.errors, status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        # when you don't make it shareable, the note doesn't save and thus redirects to the else
        if @note.save

          current_user.friends.each do |friend|
            message_body = ActivityRenderer.new.generate_message(friend, 'note_share', :user => current_user, :note => @note)
            ActivityMessage.create(:user_id => friend.id, :body => message_body, :activist => current_user)
          end
          format.html { redirect_to @note, notice: 'Note was successfully created.' }
          format.json { render json: @note, status: :created, location: @note }
        else
          format.html { redirect_to @note, notice: 'Note was successfully created.' }
          format.json { render json: @note.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    @note = current_user.permissions.find_by_note_id(params[:id]).permission_setting.note
    if params[:content].blank?
      respond_to do |format|
        if @note.update_attributes(params[:note])
          format.js {}
          format.html { redirect_to @note, notice: 'Note was successfully updated.' }
          format.json { head :ok }
        else
          format.html { render action: "edit" }
          format.json { render json: @note.errors, status: :unprocessable_entity }
        end
      end
    else
      @note.content = params[:content]
      @note.save
      render :text => @note.content
    end
  end

  def move
    if @folder
      @note.folder = @folder
    end
    if @notebook && @notebook.id != @note.notebook_id
      @note.notebook_id = @notebook.id
    else
      #Move the note out of a notebook
      @note.notebook_id = nil
    end

    respond_to do |format|
      if @folder
        if @note.save
          @folder.reload
          format.json do
            html = render_to_string(partial: 'notes/child_note.html.erb', locals: { note_item: NoteItem.new(@folder), note: @note })
            render json: { html: html }
          end
        end
      else
        if @note.save
          @notebook.reload
          format.json do
            if @note.notebook
              html = render_to_string(partial: 'notes/child_note.html.erb', locals: { note_item: NoteItem.new(@notebook), note: @note })
            else
              html = render_to_string(partial: 'notes/note_item.html.erb', locals: { note_item: NoteItem.new(@note) })
            end
            render json: { html: html }
          end
        else
          format.json { render json: @note.errors, status: :unprocessable_entity }
        end
      end
    end
  end
  
  def delete
    @note = current_user.notes.find(params[:id])
  end
  
  def destroy
    @note = current_user.notes.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.html { redirect_to ( @note.notebook ? notebook_path(@note.notebook.id) : notebooks_path ) }
    end
  end

  def request_access
    @note = Note.find(params[:id])
 #   push_broadcast :request_access, :note_id => @note.id, :sender => current_user, :receiver => @note.owner, :note => @note

    uri = URI.parse(APP_CONFIG["faye"])
    options = {:note_id => @note.id, :sender => current_user, :receiver => @note.owner, :note => @note}
    message = "#{current_user.title_name} has requested access to one of your notes."
    data = {:user_id => @note.owner.id, :note_id => @note.id, :message => message, :intent => "note_request", :current => true, :args => options}
    serialized_data = data.to_json
    notification = {:channel => "/broadcasts/user/#{@note.owner.id}", :data => serialized_data}
    Net::HTTP.post_form(uri, :message => notification.to_json) if Broadcast.create(data)

    #Notifier.request_note_access(current_user, @note).deliver
    respond_to do |format|
      format.js
    end
  end
  
  def copy
    @old_note = Note.find(params[:id])
    @new_note = @old_note.dup
    @new_note.name = "Copy of " + @old_note.name
    @new_note.build_permission_setting
    @new_note.user = current_user
    @new_note.save!
    redirect_to @new_note
  end

  protected

    def find_note
      if Note.find_by_id(params[:id]) and current_user.can_view?(Note.find_by_id(params[:id]))
        @note = Note.find_by_id(params[:id])
      else
        @note = Note.new
      end
    end

    def find_notebook
      #@notebook = Notebook.viewable_by(current_user).find_by_id(params[:notebook_id]) || @note.try(:notebook)
      #@notebook = Notebook.find_by_id(params[:notebook_id]) || @note.try(:notebook)
      @notebook = Notebook.where(:user_id => current_user.id).find_by_id(params[:notebook_id])
      if @note && @note.notebook_id.nil?
        @note.notebook = @notebook
      end
    end
    
    def find_folder
      @folder = Folder.where(:user_id => current_user.id).find_by_id(params[:folder_id])
    end

    def set_action_bar
      return true unless action_name == "index"
      @action_bar = File.exists?("app/views/#{params[:controller]}/_action_bar.html.erb") ? "#{params[:controller]}/action_bar" : nil
      flash[:action_bar_message] ||= nil
    end

end
