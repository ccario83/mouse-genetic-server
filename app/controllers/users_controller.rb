class UsersController < ApplicationController
	before_filter :signed_in_user,	:only => [:index, :edit, :update, :destroy, :edit, :update]
	before_filter :admin_user, 		:only => :destroy

	def index
		@users = User.order(:last_name).paginate(:page => params[:page], :per_page => 28)
	end


	def show
		#@user = User.find(params[:id])
		@user = current_user
		
		# CAUTION: the :per_page values MUST MATCH their respective controller/reload :per_page values... Its best to use the defaults set in the models  
		
		@microposts = @user.all_received_posts.sort_by(&:created_at).reverse.paginate(:page => params[:microposts_paginate], :per_page => 8)
		@micropost = @user.authored_posts.new
		
		@confirmed_groups = @user.confirmed_groups.sort_by(&:name).paginate(:page => params[:confirmed_groups_paginate], :per_page => 5)
		@associated_users = @confirmed_groups.map(&:users).flatten.uniq.sort_by(&:name)
		
		@jobs = @user.jobs.sort_by(&:created_at).reverse.paginate(:page => params[:jobs_paginate], :per_page => 4)
		@job = Job.find(params[:job_id]) if params.has_key?(:job_id)
		
		@datafiles = @user.datafiles.sort_by(&:created_at).reverse.paginate(:page => params[:datafiles_paginate], :per_page => 4)
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
		debugger
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
			@group.destroy
			# Return the data to the client so jQuery can update page
			render :json => { :type => 'delete', :id => @id }.to_json
		end
	end

=begin AJAX job loading
	def job
		# Get the id of the job to show
		@job = Job.find(params['id']) # id is what comes after the slash in 'uwf/show/#' by default
		# Also display the circos plot thumbnail if it is ready
		if $redis.get("#{current_user.redis_key}:#{@job.redis_key}:completed") == 'true'
			@circos_thumb = File.join('/data', @job.creator.redis_key, 'jobs', @job.redis_key, '/Plots/circos.png')
		end
		
		render :partial => 'uwf/uwf_center_panel', :locals => { job: @job, circos_thumb: @circos_thumb }, :as => :json
	end
=end 

	private
		def admin_user
			redirect_to root_path unless current_user.admin?
		end
end
