class TasksController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy
	before_filter :suspicious?, :only => :create # Verify hidden fields weren't altered

	def create
		# @user = User.find(params[:user_id]) # Less safe... can be faked. 
		@user = current_user
		@group = Group.find(params[:task][:group_id].to_i)
		@creator = User.find(params[:task][:creator_id].to_i)
		@assignee_id = params[:task][:assignee_id].to_i
		@members = @group.members.sort_by(&:last_name).paginate(:page => params[:members_paginate], :per_page => 5)
		
		if !(@assignee_id == 0)
			@assignee = User.find(params[:task][:assignee_id].to_i)
		end
		
		@task = Task.new({:creator => @creator, :group => @group, :assignee => @assignee, :description => params[:task][:description], :due_date => params[:task][:due_date]})
		
		if @task.save
			flash[:success] = "The task was successfully created."
		else
			flash[:error] = "Please correct form errors."
		end
		respond_to do |format|
			format.js { render :controller => "tasks", :action => "create" } and return
		end
		
	end

	def destroy
		if @task.destroy
			flash[:success] = "The task was successfully deleted."
		else
			flash[:error] = "The task deletion failed!"
		end
		
		respond_to do |format|
			format.js { }
			format.html {  }
		end
	end

	def check
		@id = params['id'].to_i
		@task = Task.find(@id)
		
		if (@task.creator == current_user || @task.assignee == current_user)
			@task.toggle!(:completed)
			render :json => @id.to_json
		else
			render :json => nil.to_json
		end
	end

	def reload
		id = params[:id]
		type = params[:type]
		page = params[:tasks_paginate]

		page = 1 if @page==""
		
		@user = current_user
		@group = Group.find(id)

		@task = @user.created_tasks.new({:group_id => @group.id, :creator_id => @user.id })
		@tasks = @group.tasks.paginate(:page => page, :per_page => 8)
		
		respond_to do |format|
			format.js { render :controller => "tasks", :action => "reload" }
		end
	end

	private
		def correct_user
			@task = current_user.created_tasks.find_by_id(params[:id])
			if @task.nil?
				flash[:error] = "The task ownership verification failed!"
				redirect_to :back
			end
		end
		
		def suspicious?
			# See if one of the current user's group's id matches the one from the form
			if !(current_user.groups.map(&:id).include?params[:task][:group_id].to_i)
					flash[:error] = "Nice try h4x0r..."
					redirect_to :back
			elsif !(current_user.id == params[:task][:creator_id].to_i)
					flash[:error] = "Nice try h4x0r..."
					redirect_to :back
			end
		end
end
