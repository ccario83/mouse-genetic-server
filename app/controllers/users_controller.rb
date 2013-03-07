class UsersController < ApplicationController
	before_filter :signed_in_user,	:only => [:index, :edit, :update, :destroy]
	before_filter :correct_user, 	:only => [:edit, :update]
	before_filter :admin_user, 		:only => :destroy
	
	def index
		@users = User.paginate(:page => params[:page], :per_page => 28)
	end

	def show
		@user = User.find(params[:id])
		@microposts = @user.all_recieved_posts.paginate(:page => params[:microposts_paginate], :per_page => 5)
		@micropost = current_user.authored_posts.new
		@groups = @user.groups.paginate(:page => params[:groups_paginate], :per_page => 5)
	end

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])
		if @user.save
			sign_in @user
			flash[:notice] = "Account successfully created"
			redirect_to @user # Same as render 'show' with user_id (POST /users/show/id)
		else	
			render 'new' # Otherwise redirect back to the new view. Simple_form or other code will handle display of errors in the @user object
		end
	end

	def edit
	end

	def update
		if @user.update_attributes(params[:user])
			sign_in @user
			flash[:notice] = "Profile updated"
			redirect_to @user
		else
			render 'edit'
		end
	end
	
	def destroy
		User.find(params[:id]).destroy
		flash[:notice] = "User deleted"
		redirect_to :back
	end


	private
		def correct_user
			@user = User.find(params[:id])
			redirect_to root_path unless current_user?(@user)
		end

		def admin_user
			redirect_to root_path unless current_user.admin?
		end
end
