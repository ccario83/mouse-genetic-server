class GroupsController < ApplicationController
	before_filter :correct_user, 	:only => [:show]
	before_filter :not_suspicious?, :only => [:modify_members] # Verify hidden fields weren't altered


	def index
		@groups = Group.order(:name).paginate(:page => params[:page], :per_page => 24)
	end

	def new
		@group = Group.new
		@users = User.order(:last_name)
		@preselected_ids = []
	end


	def create
		@user_ids = params[:group][:user_ids]
		@users = []
		
		# Set the user list to empty for any possible empty input
		if (@user_ids.nil? or @user_ids=="[]" or @user_ids=="" or @user_ids==[""])
			@user_ids = []
		else # Try to parse the JSON if it is in JSON, otherwise attempt to 
			begin
				@user_ids = JSON.parse(@user_ids).map(&:to_i)
			rescue
				@user_ids = @user_ids.map(&:to_i)
			end
			@user_ids.delete(0) if @user_ids.include?(0)
		end

		if @user_ids.empty? # No users were selected and we don't allow groups with only the creator as a member
			flash[:error] = "You cannot create group with no non-creator members."
			redirect_to :back and return
		else
			@users = User.find(@user_ids)
		end
		@creator = current_user
		# Set the group creator and make them a group member (this are not passed in params[:group][:users] if the show_current_user flag is false in the user form
		# Since a user MUST be a member of their own group, this assures they are kept in any case
		@users.prepend(@creator) if not @users.include?@creator

		# Create the new group
		@group = Group.create(:creator => @creator, :name => params[:group][:name], :description => params[:group][:description])
		@group.users << @users
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
		@user = current_user
		@users = User.order(:last_name)
		
		@group = Group.find(params[:id])
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => params[:confirmed_groups_paginate], :per_page => 5)
		@associated_users = @confirmed_groups.map(&:users).flatten.uniq.sort_by(&:name)
		@members = @group.members.sort_by(&:last_name).paginate(:page => params[:members_paginate], :per_page => 7)

		@micropost ||= current_user.authored_posts.new({:group_recipients => [@group]})
		@microposts = @group.received_posts
		if params.has_key?(:user_filter)
			puts "{"+params[:user_filter]+"}"
			@microposts = @microposts.where(:creator_id => params[:user_filter])
		end
		@microposts = @microposts.paginate(:page => params[:microposts_paginate], :per_page => 7)

		@task ||= current_user.created_tasks.new({:group_id => @group.id, :creator_id => current_user.id })
		@tasks = @group.tasks.paginate(:page => params[:tasks_paginate], :per_page => 8)
		
		@datafiles = []
		@jobs = []
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
	
	def reload
		@user = params[:user_id]
		@page = params[:confirmed_groups_paginate]
		@user ||= current_user
		@page = 1 if @page==""
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => @page, :per_page => 5)
		render :partial => 'users/group_panel', :locals => { show_listing_on_load: true }
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


