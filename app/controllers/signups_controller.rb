class SignupsController < ApplicationController
  
  layout 'login'
  def new
    @signup = Signup.new
  end
  
  def create
    @signup = Signup.new(params[:signup])
    if @signup.save_without_session_maintenance
        if @signup.school and @signup.school.active
          @signup.deliver_activation_email
          flash[:notice] = "Thanks for your request. We'll review it and send you an invite ASAP"
        elsif @signup.school and @signup.school.name == "American U"
          flash[:error] = "Please use your @american.edu email!"
        elsif @signup.school
          flash[:notice] = "Sorry we're not at your school yet. Thanks for your interest! We'll let you know as soon as we are at your school!"
        else
          flash[:error] = "StudyHall is only open to students. Please use an .edu email if you have one"
        end
    else
      @signup_with_same_email = Signup.find_by_email(@signup.email) if @signup.errors[:email].include?('has already been taken')
      @user_with_same_email = User.find_by_email(@signup.email) if @signup.errors[:email].include?('has already been taken')
      if @user_with_same_email
        flash[:error] = "An account already exists with that email, contact us at info@studyhall.com and we'll sort it out!"
      elsif @signup_with_same_email.school
        unless @signup_with_same_email.school.active?
          flash[:error] = "Someone already signed up with that email. Contact us at info@studyhall.com and we'll sort it out!"
        else
          @signup_with_same_email.reset_perishable_token!
          @signup_with_same_email.deliver_activation_email
          flash[:notice] = "Thanks for your request. We'll review it and send you an invite ASAP"
        end
      else
        flash[:error] = "Someone already signed up with that email but we're not at your school yet!"
      end
    end

    respond_to do |format|
      format.html {flash[:notice].nil? ? render(action: :new) : redirect_to(login_url)}
      format.js
    end
      
  end
  
end
