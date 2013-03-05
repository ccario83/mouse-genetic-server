class GroupsController < ApplicationController
	before_filter :correct_user, 	:only => [:show]

	def new
		@group = Group.new
		@users = User.all
		@preselected = []
	end

	def create
		# Get a list of requested group members (users) if it isn't empty (a group will always have at least one member -- the creator)
		if params[:group][:users]=="[]" # The odd way that the form returns an emtpy list
			params[:group][:users] = []
		else
			params[:group][:users] = User.find(params[:group][:users].split(',').map(&:to_i))
		end
				
		#Set the group creator and make them a group member
		params[:group][:creator] = User.find(current_user.id)
		params[:group][:users].prepend(params[:group][:creator]) if not params[:group][:users].include?params[:group][:creator]

		# Create the new group
		@group = Group.new(params[:group])
		if @group.save
			flash[:notice] = "The new group was successfully created."
			redirect_to @group # Same as render 'show' with group_id (POST /group/show/id)
		else
			# Regenerate the user list
			@users = User.all
			@preselected = @group.users.map(&:id).to_s
			@group.users = []
			render 'new' # Otherwise redirect back to the new view. Simple_form or other code will handle display of errors in the @group object
		end
	end
	
	def show
		@group = Group.find(params[:id])
		@micropost ||= current_user.authored_posts.new({:recipient_id => @group.id, :recipient_type => 'Group'})
		@task ||= current_user.tasks.new({:group_id => @group.id, })
		
		@microposts = @group.microposts
		if params.has_key?(:user_filter)
			puts "{"+params[:user_filter]+"}"
			@microposts = @microposts.where(:creator_id => params[:user_filter])
		end
		@microposts = @microposts.paginate(:page => params[:microposts_paginate], :per_page => 3)

		@tasks = @group.tasks.paginate(:page => params[:tasks_paginate], :per_page => 3)

		@members = @group.members.paginate(:page => params[:members_paginate], :per_page => 3)
	end


	private
		def correct_user
			@group = Group.find(params[:id])
			if !(@group.members.include?current_user)
				flash[:error] = "You don't appear to be a member of that group."
				redirect_to current_user
			end
		end
end


