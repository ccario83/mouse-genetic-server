class TasksController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy
	#before_filter :suspicious?, :only => :create # Verify hidden fields weren't altered

	def create
		@task = current_user.tasks.build(params[:tasks])
		if @task.save
			flash[:success] = "The task was successfully created."
			redirect_to :back
		else
			flash[:error] = "The task creation failed (did it contain any content?)"
			redirect_to :back
		end
	end

	def destroy
		if @task.destroy
			flash[:notice] = "The task was successfully deleted."
			redirect_to :back
		else
			flash[:error] = "The task deletion failed!"
		end
	end

	private
		def correct_user
			@task = current_user.tasks.find_by_id(params[:id])
			if @task.nil?
				flash[:error] = "The task ownership verification failed!"
				redirect_to :back
			end
		end
		
		def suspicious?
			
			if !(current_user.groups.map(&:id).include?params[:tasks][:group_id])
					flash[:error] = "Nice try h4x0r..."
					redirect_to :back
			end
		end
end
