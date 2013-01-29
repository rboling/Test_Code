class SignupVerificationsController < ApplicationController
  
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token
  
  skip_before_filter :require_not_new_user
  
  def show
    if @signup #This means that the signup clicked the link in the correct amount of time
      #bring them to the fb authenticate page
      @user = User.new
      @user.email = @signup.email
      @user.school = @signup.school
      @user.password = User.random_string(10) #generate a random password that the user will reset on their account page
      @user.custom_url = @signup.id.to_s + "w"
      if @user.save #basically if the account hasn't already been activated and already exists
        
        @user.activate! #activates
        session[:ep_sessions] = {}
        @user_session = UserSession.create(@user, true) # logs the user in
        unless params[:offering_id].nil?
          @offering = Offering.find(params[:offering_id])
          #redirect_to class_verify_show_path(@offering.id)
          redirect_to "/classes/#{@offering.to_param}"
        else
          redirect_to ('/users/' + @user.id.to_s + '/welcome')
        end
      else
        flash[:notice] = "Sorry, an account with that email already exists, please login"
        redirect_to ('/login')
      end
    else
      flash[:notice] = "Sorry, we were unable to find your account."
      redirect_to ('/login')
    end
  end
  
  private

  def load_user_using_perishable_token
    @signup = Signup.find_using_perishable_token(params[:id])
    flash[:notice] = "Unable to find your account." unless @signup
  end
  
end
