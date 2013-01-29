class PermissionSettingsController < ApplicationController
  
  before_filter :require_user
    
  def edit
    @permission_set = PermissionSetting.find(params[:id])
    unless current_user.can_edit?(@permission_set.note)
      redirect_to notes_path
    end
  end
  
  def update
    @permission_set = PermissionSetting.find(params[:id])
    if @permission_set.update_attributes(params[:permission_setting])
      redirect_to @permission_set.note
    else
      render :edit
    end
  end
  
end
