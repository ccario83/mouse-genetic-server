class MicropostsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy
	before_filter :suspicious?, :only => :create # Verify hidden fields weren't altered

	def create
		#@micropost = current_user.authored_posts.build(params[:micropost])
		if @micropost.save
			flash[:success] = "The micropost was successfully created."
			redirect_to :back
		else
			flash[:error] = "A micropost should contain content."
			redirect_to :back
		end
	end

	def destroy
		if @micropost.destroy
			flash[:notice] = "The micropost was successfully deleted."
			redirect_to :back
		else
			flash[:error] = "The micropost deletion failed!"
		end
	end

	private
		def correct_user
			@micropost = current_user.authored_posts.find_by_id(params[:id])
			if @micropost.nil?
				flash[:error] = "The micropost ownership verification failed!"
				redirect_to :back
			end
		end
		
		def suspicious?
			@micropost = current_user.authored_posts.build(params[:micropost])
			if @micropost.recipient_type == 'Group'
				if !(@micropost.creator.groups.map(&:id).include?(@micropost.recipient_id))
					flash[:error] = "Nice try h4x0r..."
					redirect_to :back
				end
			end
		end
end
