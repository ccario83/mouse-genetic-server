class UsersController < ApplicationController
	before_filter :signed_in_user,	:only => [:index, :edit, :update, :destroy]
	before_filter :correct_user, 	:only => [:edit, :update]
	before_filter :admin_user, 		:only => :destroy
	

	def index
		@users = User.order(:last_name).paginate(:page => params[:page], :per_page => 28)
	end


	def show
		@user = User.find(params[:id])
		@microposts = @user.all_recieved_posts.paginate(:page => params[:microposts_paginate], :per_page => 5)
		@micropost = current_user.authored_posts.new
		@all_groups = @user.groups.order(:name)
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => params[:confirmed_groups_paginate], :per_page => 5)
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


	# AJAX handlers for group-management clicks
	def accept_group
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to do this
		if (not current_user.is_member?(@group)) || (current_user.confirmed_member?(@group))
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			current_user.confirm_membership(@group)
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'accept', :id => @id }.to_json
		end
	end
	
	def decline_group
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to do this
		if (not current_user.is_member?(@group)) || (current_user.confirmed_member?(@group))
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			current_user.memberships.where(:group_id => @group.id)[0].destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'decline', :id => @id }.to_json
		end
	end
	
	def leave_group
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to do this and also that the current_user isn't a creator
		if (not current_user.is_member?(@group)) || (current_user == @group.creator)
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			current_user.memberships.where(:group_id => @group.id)[0].destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'leave', :id => @id }.to_json
		end
	end
	
	def delete_group
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to do this
		if @group.creator != current_user
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			# @group.destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'delete', :id => @id }.to_json
		end
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
