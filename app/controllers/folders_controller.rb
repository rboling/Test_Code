class FoldersController < ApplicationController
  
  def index
    @folders = current_user.folders
  end
  
end
