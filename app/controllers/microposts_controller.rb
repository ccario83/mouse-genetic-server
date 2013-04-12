class MicropostsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy

	def create
		@recipient_type = params[:micropost][:recipient_type]
		@content = params[:micropost][:content]
		
		@group_ids = params[:micropost][:group_recipient_ids]
		@user_ids = params[:micropost][:user_recipient_ids]

		## REALLY UGLY CODE DUE TO CHOSEN'S METHOD OF SENDING IDs
		# Parse the group and user ids
		if (@group_ids=="[]" or @group_ids=="" or @group_ids==[""])
			@group_ids = current_user.groups.map(&:id)
		else
			begin
				@group_ids = JSON.parse(params[:micropost][:group_recipient_ids]).map(&:to_i)
			rescue
				@group_ids = params[:micropost][:group_recipient_ids].map(&:to_i)
			end
			@group_ids.delete(0) if @group_ids.include?(0)
		end
		if (@user_ids=="[]" or @user_ids=="" or @user_ids==[""])
			@user_ids = current_user.confirmed_groups.map(&:users).flatten.uniq.map(&:id)
		else
			begin
				@user_ids = JSON.parse(params[:micropost][:user_recipient_ids]).map(&:to_i)
			rescue
				@user_ids = params[:micropost][:user_recipient_ids].map(&:to_i)
			end
			@user_ids.delete(0) if @user_ids.include?(0)
		end
		
		# Convert the ids to a recipient list for the requested type (group or user post), and check that the current_user has permissions to post to these
		@recipients = []
		if @recipient_type.nil? || @recipient_type == 'group'
			@recipients = Group.find(@group_ids)
			allowed_recipients = current_user.groups
			if !(@recipients.map{|x| allowed_recipients.include?(x)}.all?)
				flash[:error] = "Nice try h4x0r..."
				redirect_to :back
			end
		elsif @recipient_type == 'user'
			@recipients = User.find(@user_ids)
			allowed_recipients = current_user.confirmed_groups.map(&:users).flatten.uniq
			if !(@recipients.map{|x| allowed_recipients.include?(x)}.all?)
				flash[:error] = "Nice try h4x0r..."
				redirect_to :back
			end
		end
		
		# Post the message
		post_was_successful = false
		if @recipient_type == 'group'
			post_was_successful = current_user.post_message_to_groups(@recipients, @content)
		elsif @recipient_type == 'user'
			post_was_successful = current_user.post_message_to_users(@recipients, @content)
		end
		
		if	post_was_successful
			flash[:success] = "The micropost was successfully created."
			redirect_to :back
		else
			flash[:error] = "A micropost should contain content and recipient(s)."
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
	
	def reload
		user = params[:user_id]
		page = params[:microposts_paginate]
		user ||= current_user
		page = 1 if page==""
		microposts = user.all_received_posts.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 5)
		render :partial => 'shared/micropost_listing', :locals => { microposts: microposts }
	end
	
	private
		def correct_user
			@micropost = current_user.authored_posts.find_by_id(params[:id])
			if @micropost.nil?
				flash[:error] = "The micropost ownership verification failed!"
				redirect_to :back
			end
		end
end
