class JobsController < ApplicationController
	before_filter :signed_in_user
	#before_filter :correct_user, :only => :destroy

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

	# DELETE /user/:user_id/jobs/:id
	def destroy
		@job = Job.find(params[:id])
		# Verify the user owns the job
		if not @job.creator == current_user
			flash[:error] = "You don't own this job."
		end
		@job.destroy
		redirect_to "/users/#{current_user.id}"
	end

	def reload
		id = params[:id]
		type = params[:type]
		page = params[:jobs_paginate]
		page = 1 if @page==""

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
			return "Error loading new data! A viewing user or group was not defined."
		end
		
		@jobs = @user.jobs.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 4)
		render :partial => 'shared/job_panel', :locals => { viewer: @user, show_listing_on_load: true }
	end

	def percentages
		job_ids = JSON.parse(params[:ids])
		percentages = Hash[job_ids.sort.zip(Job.find(job_ids).map(&:progress))]
		# replace nils with 0
		percentages.each{|k,v| percentages[k] = 0 if v.nil?}
		render :json => percentages.to_json
	end
end
