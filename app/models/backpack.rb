Notable = Struct.new(:id, :created_at, :class_name)
class Backpack
  
  def initialize(user)
    @user = user
  end

  def contents(options={})
    @options = options
    # Need a completely different method for finding filtered notes because you want to find notes that are in notebooks.
    # What about when note or notebooks is not checked in the filter form
    if @options[:folder].nil?
      @folders = find_folders
    else
      @folders = []
    end
    @notes = find_notes
    @notebooks = (@typed || @user.is_a?(Group)) ? [] : find_notebooks
    @notables = (@folders + @notebooks + @notes.sort_by(&:created_at).reverse)
    @start_index, @end_index = nil, nil
    fetch_contents(@notables[start_index..end_index])
    
  end

  private
    
    def create_notables(records)
      records.map{|n| Notable.new(n.id, n.created_at, n.class.to_s) }
    end
    
    def find_notes
      if @options[:filter].nil?
        if @options[:doc_type].nil? || @options[:doc_type] == "0"
          if @options[:folder].nil?
            create_notables @user.notes.unsorted.select([:id, :created_at]).all
          else
            if Folder.find(@options[:folder]).name == "Notes Shared With You"
              @docs = Array.new
              @user.permissions.each do |p|
              begin
                if p.permission_setting.note.user != @user
                  n = p.permission_setting.note
                  @docs << Notable.new(n.id, n.created_at, n.class.to_s)
                end
              rescue
              end
              end
              return @docs
            elsif Folder.find(@options[:folder]).name == "Other"
              #basically find all docs in other folder and all docs with folder_id == nil
              create_notables @user.notes.where(:folder_id => [@options[:folder], nil]).select([:id, :created_at]).all
            else
              create_notables @user.notes.where(:folder_id => @options[:folder]).select([:id, :created_at]).all
            end
          end
        else
          if @options[:folder].nil?
            @typed = true
            create_notables @user.documents(@options[:doc_type]).unsorted.select([:id, :created_at]).all
          else
            @typed = true
            create_notables @user.documents(@options[:doc_type]).where(:folder_id => @options[:folder]).select([:id, :created_at]).all
          end
        end
      elsif @options[:filter][:notes] == "1"
        create_notables Note.filter_for(@user, @options[:filter])
      else
        []
      end
    end
    
    def find_folders
      if @options[:filter].nil?
        if @options[:doc_type].nil? || @options[:doc_type] == "0"
            create_notables @user.folders.select([:id, :created_at]).all
        else
          []
        end
      else
        []
      end
    end
    
    def find_notebooks
      if @options[:filter].nil?
        if @options[:folder].nil?
          create_notables @user.alpha_ordered_notebooks(:folder_id => nil)
        else
          create_notables @user.notebooks.select([:id, :created_at]).where(:folder_id => @options[:folder])
        end
      elsif @options[:filter][:notebooks] == "1"
        create_notables Notebook.filter_for(@user, @options[:filter])
      else
        []
      end
    end

    def page
      return 1 if @options[:page].nil?
      page = @options[:page].to_i
      return page if page > 0
      raise ArgumentError.new("Backpack#contents expects :page option to be string or integer representing non-zero, non-negative number")
    end

    def per_page
      return 24 if @options[:per_page].nil?
      per_page = @options[:per_page].to_i
      return per_page if per_page > 0
      raise ArgumentError.new("Backpack#contents expects :per_page option to be string or integer representing non-zero, non-negative number")
    end

    def start_index
      @start_index ||= page.to_i < 2 ? 0 : ((page-1) * per_page)
    end

    def end_index
      @end_index ||= @notables.size >= (start_index + per_page - 1) ? (start_index + per_page - 1) : (@notables.size - 1)
    end
  
    def fetch_contents(notables)
      notables ||= []
      notables.map do |notable|
        notable.class_name.constantize.send(:find, notable.id)
      end
    end

end
