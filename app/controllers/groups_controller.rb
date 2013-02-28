class GroupsController < ApplicationController
	before_filter :correct_user, 	:only => [:show]

	def new
		@group = Group.new
		@users = User.all
	end

	def create
		# Get the stringified User id list get the associated user objects
		params[:group][:users] = User.find(params[:group][:users].split(',').map(&:to_i))
		#Set the group creator
		params[:group][:creator] = User.find(current_user.id)

		# Create a new group
		@group = Group.new(params[:group])
		if @group.save
			flash[:notice] = "Account successfully created"
			redirect_to @group # Same as render 'show' with group_id (POST /group/show/id)
		else	
			render 'new' # Otherwise redirect back to the new view. Simple_form or other code will handle display of errors in the @group object
		end
	end
	
	def show
		@group = Group.find(params[:id])
		@micropost = current_user.authored_posts.new({:recipient_id => @group.id, :recipient_type => 'Group'})
		@microposts = @group.microposts.paginate(:page => params[:microposts_paginate], :per_page => 3)
		@members = @group.members.paginate(:page => params[:members_paginate], :per_page => 3)
	end

	private
		def correct_user
			@group = Group.find(params[:id])
			if !(@group.members.include?current_user)
				flash[:error] = "You don't appear to be a member of that group"
				redirect_to current_user
			end
		end
end


