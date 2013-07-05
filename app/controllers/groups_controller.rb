class GroupsController < ApplicationController
	before_filter :correct_user, 	:only => [:show]
	before_filter :not_suspicious?, :only => [:modify_members] # Verify hidden fields weren't altered


	# The group index page for admins
	def index
		@groups = Group.order(:name).paginate(:page => params[:page], :per_page => 24)
	end

	# To create a new group
	def new
		@group = Group.new
		@users = User.order(:last_name)
		@preselected_ids = []
	end

	# To create a new group
	def create
		# Set the user as the current user. Add the form params to a new group
		@user = current_user
		@group = Group.create(:creator => @user, :name => params[:group][:name], :description => params[:group][:description])
		
		# Add group users
		@users = User.find(cleanup_ids(params[:group][:user_ids]))
		# Set the group creator and make them a group member (this are not passed in params[:group][:users] if the show_current_user flag is false in the user form
		# Since a user MUST be a member of their own group, this assures they are kept in any case
		@users.prepend(@user) if not @users.include?@user
		@group.users << @users
		
		# Save the group and set flash messages
		if @group.save
			flash[:success] = "The new group was successfully created."
			# Auto confirm the creator to his/her own group
			@user.confirm_membership(@group)
		else
			puts @group.errors.messages
			# Regenerate the user list
			flash[:error] = "Please correct form errors."
			@preselected = @group.users.map(&:id).to_s
			@group.users = []
		end
		
		respond_to do |format|
			format.js { render :controller => "groups", :action => "create" }
		end
	end
	
	# This is the main page for the group centric view. 
	def show
		# Set the user to current_user, the viewer (used to help render view based on user/group context), and group
		@user = current_user
		@group = Group.find(params[:id])
		@viewer = @group
		
		# CAUTION: the :per_page values MUST MATCH their respective controller/reload :per_page values... Its best to use the defaults set in the models  
		# This is the displayed group member list
		@members = @group.members.sort_by(&:last_name).paginate(:page => params[:members_paginate], :per_page => 5)
		
		# Variables required by #member-panel
		#===========================================
		@datafiles = @group.datafiles.sort_by(&:created_at).reverse.paginate(:page => params[:datafiles_paginate], :per_page => 4)
		
		# Variables required by #job-panel
		#===========================================
		@jobs = @group.jobs.sort_by(&:created_at).reverse.paginate(:page => params[:jobs_paginate], :per_page => 4)
		
		# Variables used by #micropost-panel
		#===========================================
		# The paginated list of microposts
		@micropost ||= current_user.authored_posts.new({:group_recipients => [@group]})
		@microposts = @group.all_received_posts
		if params.has_key?(:user_filter)
			@microposts = @microposts.where(:creator_id => params[:user_filter])
		end
		@microposts = @microposts.sort_by(&:created_at).reverse.paginate(:page => params[:microposts_paginate], :per_page => 8)
		# Partial defaults for others

		# Variables used by #micropost-panel
		#===========================================
		@task ||= current_user.created_tasks.new({:group_id => @group.id, :creator_id => current_user.id })
		@tasks = @group.tasks.paginate(:page => params[:tasks_paginate], :per_page => 8)
		
	end
	
	# An AJAX function to modify group membership
	def modify_members
		# Get the group id, the updated member id list, and initialize the membership list
		@group = Group.find(params[:id].to_i)
		@modified_user_ids = cleanup_ids(params[:group][:user_ids])
		@modified_users = []
		
		# Get member information for the member id list and make sure the group has at least its creator as a member
		if @modified_user_ids.empty? # All non-owner users were removed. This prevents letting the user from making a group that only he/she belongs to
			@modified_users = @group.creator
		else
			@modified_users = User.find(@modified_user_ids)
		end
		
		# Set the group creator and make them a group member (this are not passed in params[:modified][:users] if the show_current_user flag is false in the form
		# Since a user MUST be a member of their own group, this assures they are kept in any case
		@modified_users.prepend(@group.creator) if not @modified_users.include?@group.creator
		
		# Set flash messages
		if @group.update_attributes(:users => @modified_users)
			flash[:success] = "The group's members were successfully modified."
		else
			flash[:error] = "There was an error modifying the group's members"
		end

		# Respond via javascript (again, an update is an AJAX request)
		respond_to do |format|
			format.js { render :controller => "groups", :action => "update" }
		end

	end
	
	# This action is responsible for reloading the group div content on the user's page
	def reload
		# get the user id and the pagination for the group list, or default to 1
		id = params[:id]
		type = params[:type]
		page = params[:confirmed_groups_paginate]
		page = 1 if @page==""

		# The user is the current_user by default, and confirmed groups are those that the user has accepted memebership to
		@user ||= current_user
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => page, :per_page => 5)
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true
		
		# Render the new div information using AJAX
		respond_to do |format|
			format.js { render :controller => "groups", :action => "reload" }
		end
	end
	
	# A couple functions to validate permissions
	private
		def correct_user
			@group = Group.find(params[:id])
			if !(@group.members.include?current_user)
				flash[:error] = "You don't appear to be a member of that group."
				redirect_to current_user
			end
		end
		
		def not_suspicious?
			@group = Group.find(params[:id].to_i)
			if not (@group.creator == current_user)
				flash[:error] = "You shouldn't play with hidden fields..."
				redirect_to :back
				return
			end
		end
end


