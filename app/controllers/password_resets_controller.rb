class PasswordResetsController < ApplicationController
 before_action :get_user,only:[:edit, :update]
 before_action :valid_user,only:[:edit, :update]
 before_action :check_expiration, only:[:edit, :update] #case1
 
 
  def new
  end

  def edit
  end
  
  def create
    @user =User.find_by(email: params[:password_reset][:email].downcase)
        if @user 
            @user.create_reset_digest
            @user.send_password_reset_email
            flash[:info]="Email sent with password reset instrucrions"
            redirect_to root_url
        else
            flash.now[:danger] = "Email address not found"
            render 'new'
        end
  end
  
  def update
    if params [:user][:password].empty?  #case3
      @user.errors.add(:password, "can't be empty?") #case3
      
      elsif @user.update_attributes(user_params) #case4
      log_in @user
      flash[:sucsess] = "Password has been reset."
      redirect_to @user
      else
      render 'edit' #case2
    end
end
  
  
 private
  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
  
  def get_user
      @user =User.find_by(email: params[:email])
  end


  def valid_user
      unless (@user && @user.activated? && 
      @user.authenticated?(:reset, params[:id]))
      redirect_to root_url
      end
  end
  
  def check_expiration
    if @user.password_reset_expired?
      flash[:danger] = "Password reset has expired."
      redirect_to new_password_reset_url
    end
  end
end