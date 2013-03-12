class GroupsController < ApplicationController
	before_filter :correct_user, 	:only => [:show]
	before_filter :not_suspicious?, :only => [:modify_members] # Verify hidden fields weren't altered

	def new
		@group = Group.new
		@users = User.all
		@preselected_ids = []
	end

	def create
		@user_ids = []
		@users = []
		if not (params[:group][:users]=="[]")
			@user_ids = params[:group][:users].split(',').map(&:to_i)
			@user_ids.delete(0) if @user_ids.include?(0)
		end

		if @user_ids.empty? # No users were selected and we don't allow groups with only the creator as a member
			flash[:error] = "You cannot create group with no non-creator members."
			redirect_to :back and return
		else
			@users = User.find(@user_ids)
		end
		puts @users
		@creator = current_user
		# Set the group creator and make them a group member (this are not passed in params[:group][:users] if the show_current_user flag is false in the user form
		# Since a user MUST be a member of their own group, this assures they are kept in any case
		@users.prepend(@creator) if not @users.include?@creator

		# Create the new group
		@group = Groups.new(:creator_id => @creator.id, :name => params[:group][:name], :description => params[:group][:description], :users => @users)
		if @group.save
			flash[:notice] = "The new group was successfully created."
			# Auto confirm the creator to his/her own group
			current_user.confirm_membership(@group)
			redirect_to @group and return # Same as render 'show' with group_id (POST /group/show/id)
		else
			puts @group.errors.messages
			# Regenerate the user list
			flash[:error] = "Group creation failed, please check the form for errors."
			@users = User.all
			@preselected = @group.users.map(&:id).to_s
			@group.users = []
			render 'new' # Otherwise redirect back to the new view. Simple_form or other code will handle display of errors in the @group object
		end
	end
	
	def show
		@users = User.all
		@group = Group.find(params[:id])
		@micropost ||= current_user.authored_posts.new({:recipient_id => @group.id, :recipient_type => 'Group'})
		@task ||= current_user.created_tasks.new({:group_id => @group.id, :creator_id => current_user.id })
		
		@microposts = @group.microposts
		if params.has_key?(:user_filter)
			puts "{"+params[:user_filter]+"}"
			@microposts = @microposts.where(:creator_id => params[:user_filter])
		end
		@microposts = @microposts.paginate(:page => params[:microposts_paginate], :per_page => 7)

		@tasks = @group.tasks.paginate(:page => params[:tasks_paginate], :per_page => 7)

		@members = @group.members.paginate(:page => params[:members_paginate], :per_page => 7)
		@member_ids = @members.map(&:id)
	end
	
	def modify_members
		@group = Group.find(params[:modified][:group_id].to_i)
	
		@modified_user_ids = params[:modified][:users].split(',').map(&:to_i)
		@modified_user_ids.delete(0) if @modified_user_ids.include?(0)
		@modified_users = []
		
		if @modified_user_ids.empty? # All non-owner users were removed. This prevents letting the user from making a group that only he/she belongs to
			flash[:error] = "You cannot remove everyone from a group. Delete the group instead."
			redirect_to :back and return
		else
			@modified_users = User.find(@modified_user_ids)
		end
				
		# Set the group creator and make them a group member (this are not passed in params[:modified][:users] if the show_current_user flag is false in the form
		# Since a user MUST be a member of their own group, this assures they are kept in any case
		@modified_users.prepend(@group.creator) if not @modified_users.include?@group.creator
		
		if @group.update_attributes(:users => @modified_users)
			flash[:notice] = "The group's members were successfully modified."
			redirect_to :back # Same as render 'show' with group_id (POST /group/show/id)
		else
			flash[:error] = "There was an error modifying the group's members"
			redirect_to @group
		end
	end
	
	
	private
		def correct_user
			@group = Group.find(params[:id])
			if !(@group.members.include?current_user)
				flash[:error] = "You don't appear to be a member of that group."
				redirect_to current_user
			end
		end
		
		def not_suspicious?
			@group = Group.find(params[:modified][:group_id].to_i)
			if not (@group.creator == current_user)
				flash[:error] = "You shouldn't play with hidden fields..."
				redirect_to :back
				return
			end
		end
end


