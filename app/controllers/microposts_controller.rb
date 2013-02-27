class MicropostsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy

	def create
		@micropost = current_user.microposts.build(params[:micropost])
		#@micropost = Micropost.new({:creator_id=>1, :recipient_id => 4, :recipient_type => 'Group', :content => 'Hi group!'})

		
		if @micropost.save
			flash[:success] = "Micropost created!"
			redirect_to :back
		else
			@feed_items = []
			@user = current_user
			render 'users/show'
		end
	end

	def destroy
		@micropost.destroy
		flash[:notice] = "Post deleted"
		redirect_to :back
	end

	#private
	#	def correct_user
	#		@micropost = current_user.microposts.find_by_id(params[:id])
	#		redirect_to root_path if @micropost.nil?
	#	end
end
