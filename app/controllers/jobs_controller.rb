class JobsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => [:update, :destroy]

	# GET /user/:user_id/jobs/:id
	def show
		#@user = User.find(params[:user_id])
		@user = current_user
		@job = Job.find(params[:id])
		
		# Verify the user owns the job
		if not @job.creator == @user
			flash[:error] = "You don't own this job."
			redirect_to :back
		end
		
		# If the job is a UWF job and finished, save the circos root URL path (which is /data/user_key/jobs/job_key/Plots)
		if @job.runner == 'UWF' and @job.state == 'Completed'
			@job.store_parameter(:circos_root => File.join('/data', @job.creator.redis_key, 'jobs', @job.redis_key, '/Plots/'))
			@job.save!
		end
		
		# And redirect to the user show controller/action telling it to render the job in the center panel (b/c job_id is specified)
		redirect_to :controller => :users, :action => :show, :id => @user.id, :job_id => @job.id
		return
	end

	# GET /user/:user_id/jobs/:id/edit
	def edit
		#@job = Job.find(params[:id])
	end

	# Handles the record update from the data that the user sends from the edit form
	def update
		# Get the new description and a list of group ids which this job is now shared with
		@job.description = params['job']['description']
		@job.groups = Group.find(cleanup_ids(params['job']['group_ids']))
		
		# Set the flash message
		if @job.save
			flash[:success] = "Job successfully updated."
		else
			flash[:error] = "Please correct form errors."
		end
		
		# Respond as a javascript script
		respond_to do |format|
			format.js { render :controller => "jobs", :action => "update" }
		end
	end

	# This is a simple AJAX delete action
	# DELETE /user/:user_id/jobs/:id
	def destroy
		@id = @job.id
		if @job.destroy
			flash[:success] = "The job was successfully deleted."
		else
			flash[:error] = "The job deletion failed!"
		end
		
		respond_to do |format|
			format.js { }
			format.html {  }
		end
	end

	def reload
		# See datafiles_controller's reload action for descriptions on what these do as they are the same here
		id = params[:id]
		type = params[:type]
		page = params[:jobs_paginate]
		page = 1 if @page==""
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true

		@user = nil
		@viewer = nil
		@micropost = nil
		if type == 'users'
			@user = User.find(id)
			@viewer = @user
		elsif type == 'groups'
			@user = current_user
			@viewer = Group.find(id)
		else
			return "Error loading new jobs! A viewing user or group was not defined."
		end
		
		@jobs = @user.jobs.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 4)
		
		respond_to do |format|
			format.js { render :controller => "jobs", :action => "reload" }
		end

	end

	# Returns a JSON string that is a hash of {job_id: "% complete" } to update job percentages
	def percentages
		job_ids = JSON.parse(params[:ids])
		percentages = Hash[job_ids.sort.zip(Job.find(job_ids).map(&:progress))]
		# replace nils with 0
		percentages.each{|k,v| percentages[k] = 0 if v.nil?}
		render :json => percentages.to_json
	end
	
	private
		# See if the user owns the requested job
		def correct_user
			#current_user = params[:user_id] # DONT TRUST
			@job = current_user.jobs.find_by_id(params[:id])
			if @job.nil?
				flash[:error] = "The job creator verification failed!"
				redirect_to :back
			end
		end
end
