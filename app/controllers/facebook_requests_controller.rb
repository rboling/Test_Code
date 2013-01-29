class FacebookRequestsController < ApplicationController
  
  def create
    id = params[:id]
    @request = FacebookRequest.new()
    @request.request_id = id.to_s
    debugger
    @request.offering_id = params[:offering]
    @request.save
    render :nothing
  end
end
