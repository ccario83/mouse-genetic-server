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
		@user = params[:user_id]
		@page = params[:jobs_paginate]
		@user ||= current_user
		@page = 1 if @page==""
		@jobs = @user.jobs.sort_by(&:created_at).reverse.paginate(:page => @page, :per_page => 5)
		render :partial => 'shared/job_listing', :locals => { jobs: @jobs }
	end

	def percentages
		job_ids = JSON.parse(params[:ids])
		percentages = Hash[job_ids.sort.zip(Job.find(job_ids).map(&:progress))]
		# replace nils with 0
		percentages.each{|k,v| percentages[k] = 0 if v.nil?}
		render :json => percentages.to_json
	end
end
