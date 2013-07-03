class UsersController < ApplicationController
	# signed_in_user is defined in apps/helpers/session_helper and ensures a suer is signed in
	# before accessing the listed actions
	before_filter :signed_in_user,	:only => [:show, :edit, :update, :reload, :accept_group, :decline_group, :leave_group, :delete_group]
	# admin_user is defined in the private def below. This filter ensures that only admins can 
	# delete users
	before_filter :admin_user,		:only => [:index, :destroy]




	## AJAX handlers for group-management clicks
	## ==================================================
	# Renders the new user page
	def new
		# Create a new user ActiveRecord to be filled in the new view
		@user = User.new
	end


	# Attempts to create a new user
	def create
		# Gets the information filled in from the new view
		@user = User.new(params[:user])
		# Attempts to save the save the information and sign in the user, otherwise redirects 
		# back to the new view with form errors
		if @user.save
			sign_in @user
			flash[:success] = "Account successfully created."
			redirect_to @user # Same as render 'show' with user_id (POST /users/show/id)
		else
			flash[:error] = "Please correct form errors."
			render 'new' # simple_form_for will handle display of errors in the @user.erros hash
		end
	end

	# Renders the edit view to alter user information
	def edit
	end


	# Accepts user updates from the edit view or redirects back to display form errors
	def update
		if @user.update_attributes(params[:user])
			sign_in @user
			flash[:success] = "Profile successfully updated."
			redirect_to @user
		else
			flash[:error] = "Please correct form errors."
			render 'edit'
		end
	end


	## Signed in user actions
	## ==================================================
	# The main content generating action for the user page
	def show
		# The user will always be the current_user (as determined by browser session data)
		#@user = User.find(params[:id])
		@user = current_user
		
		# CAUTION: the :per_page values MUST MATCH their respective controller/reload :per_page values... Its best to use the defaults set in the models 
		
		# Variables required by #group-panel
		# --------------------------------------------------
		# confirmed groups are those the user has 'accepted'
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => params[:confirmed_groups_paginate], :per_page => 5)
		
		# Variables required by #datafile-panel
		# --------------------------------------------------
		@datafiles = @user.datafiles.sort_by(&:created_at).reverse.paginate(:page => params[:datafiles_paginate], :per_page => 4)
		
		# Variables required by #job-panel
		# --------------------------------------------------
		@jobs = @user.jobs.sort_by(&:created_at).reverse.paginate(:page => params[:jobs_paginate], :per_page => 4)
		
		# For the center panel if a user clicks on a job that (still) exists
		# --------------------------------------------------
		begin
			@job = Job.find(params[:job_id]) if params.has_key?(:job_id)
		rescue ActiveRecord::RecordNotFound
			@job = nil
		end
		
		# Variables used by #micropost-panel
		# --------------------------------------------------
		# The paginated list of microposts
		@microposts = @user.all_received_posts.sort_by(&:created_at).reverse.paginate(:page => params[:microposts_paginate], :per_page => 8)
		# To allow the user to sent a micropost to groups or users in this view
		@show_filters = true 
		# Partial defaults are used for other variables
	end


	# Regenerates the memebers_panel div as AJAX
	def reload
		# Get the group id and the pagination for the members_panel (default to 1) 
		id = params[:id]
		page = params[:members_paginate]
		page = 1 if @page==""

		# Use the current_user if not specified, load the group, and then get its members
		@user ||= current_user
		@group = Group.find(id)
		@members = @group.members.sort_by(&:last_name).paginate(:page => params[:members_paginate], :per_page => 5)
		# show_listing_on_load will determine if the div is collapsed or not when the AJAX call returns
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true
		
		# Render the members_panel div as script/js
		respond_to do |format|
			format.js { render :controller => "members", :action => "reload" }
		end
	end




	## AJAX handlers for group-management clicks (refer to app/assets/javascript/user_show.js for server side implementation)
	## ==================================================
	# Called when a user accepts a group in the group management form
	def accept_group
		# Get the group id and load it
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to accept the group (was invited) and confirm the membership
		if (not current_user.is_member?(@group)) || (current_user.confirmed_member?(@group))
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			current_user.confirm_membership(@group)
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'accept', :id => @id }.to_json
		end
	end


	# Called when a user declines a group in the group management form
	def decline_group
		# Get the group id and load it
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to decline the group (was invited) and decline the membership
		if (not current_user.is_member?(@group)) || (current_user.confirmed_member?(@group))
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			# A membership is declined by destroying the membership (request)
			current_user.memberships.where(:group_id => @group.id)[0].destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'decline', :id => @id }.to_json
		end
	end


	# Called when a user leaves a group they were previously a confirmed member of
	def leave_group
		# Get the group id and load it
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to do this and also that the current_user isn't the group creator
		if (not current_user.is_member?(@group)) || (current_user == @group.creator)
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			# A group is left by destroying the users membership to it
			current_user.memberships.where(:group_id => @group.id)[0].destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'leave', :id => @id }.to_json
		end
	end


	# Called when the user destroys the group
	def delete_group
		# Get the group id and load it
		@id = params[:id].to_i
		@group = Group.find(@id)
		
		# Verify the user has permissions to destroy the group (is the creator)
		if @group.creator != current_user
			flash[:error] = "Nice try..."
			redirect_to :back
		else
			# And destroy it
			@group.destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'delete', :id => @id }.to_json
		end
	end


	## Admin functions
	## ==================================================
	# Renders a page to list the users
	def index
		@users = User.order(:last_name).paginate(:page => params[:page], :per_page => 28)
	end

	# Destroys a user (debugger prevents accidental destruction)
	def destroy
		debugger
		User.find(params[:id]).destroy
		flash[:success] = "The user was successfully deleted."
		redirect_to :back
	end

	# Validates the current_user is an administrator
	private
		def admin_user
			redirect_to root_path unless current_user.admin?
		end
end
