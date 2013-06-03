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
		
		if @job.runner == 'UWF' and @job.state == 'Completed'
			@job.store_parameter(:circos_root => File.join('/data', @job.creator.redis_key, 'jobs', @job.redis_key, '/Plots/'))
			@job.save!
		end
		
		redirect_to :controller => :users, :action => :show, :id => @user.id, :job_id => @job.id
		return
	end

	# GET /user/:user_id/jobs/:id/edit
	def edit
		#@job = Job.find(params[:id])
	end

	def update
		@job.description = params['job']['description']
		@job.groups = Group.find(cleanup_ids(params['job']['group_ids']))
		
		if @job.save
			flash[:success] = "Job successfully updated."
		else
			flash[:error] = "Please correct form errors."
		end
		
		respond_to do |format|
			format.js { render :controller => "jobs", :action => "update" }
		end
	end

	# DELETE /user/:user_id/jobs/:id
	def destroy
		if @job.destroy
			flash[:success] = "The job was successfully deleted."
		else
			flash[:error] = "The job deletion failed!"
		end
		
		redirect_to user_path(current_user)
		#respond_to do |format|
		#	format.js { }
		#	format.html {  }
		#end
	end

	def reload
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

	def percentages
		job_ids = JSON.parse(params[:ids])
		percentages = Hash[job_ids.sort.zip(Job.find(job_ids).map(&:progress))]
		# replace nils with 0
		percentages.each{|k,v| percentages[k] = 0 if v.nil?}
		render :json => percentages.to_json
	end
	
	private
		def correct_user
			#current_user = params[:user_id] # DONT TRUST
			@job = current_user.jobs.find_by_id(params[:id])
			if @job.nil?
				flash[:error] = "The job creator verification failed!"
				redirect_to :back
			end
		end
end
