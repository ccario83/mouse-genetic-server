class SessionsController < ApplicationController
	def new
	end

	def create
		user = User.find_by_email(params[:session][:email])
		if user && user.authenticate(params[:session][:password])
  		flash[:success] = "It worked"
			sign_in user
			redirect_back_or user
		else

			flash[:error] = "Invalid email or password"
			render 'new'
		end
	end

	def destroy
		sign_out
		flash[:success] = "You have been logged out of the system"
		redirect_to root_path
	end
end
