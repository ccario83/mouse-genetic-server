class MicropostsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy

	def create
		# @user = User.find(params[:user_id]) # Less safe... can be faked. 
		@user = current_user
		
		@micropost = @user.authored_posts.new()
		@micropost.recipient_type = params[:micropost][:recipient_type]
		@micropost.content = params[:micropost][:content]
		
		group_ids = cleanup_ids(params[:micropost][:group_recipient_ids])
		user_ids = cleanup_ids(params[:micropost][:user_recipient_ids])
		
		# Convert the ids to a recipient list for the requested type (group or user post), and check that the current_user has permissions to post to these
		recipients = []
		if @micropost.recipient_type.nil? || @micropost.recipient_type == 'group'
			recipients = Group.find(group_ids)
			allowed_recipients = current_user.groups
			if !(recipients.map{|x| allowed_recipients.include?(x)}.all?)
				flash[:error] = "Nice try h4x0r..."
				redirect_to :back
			end
		elsif @micropost.recipient_type == 'user'
			recipients = User.find(user_ids)
			allowed_recipients = current_user.confirmed_groups.map(&:users).flatten.uniq
			if !(recipients.map{|x| allowed_recipients.include?(x)}.all?)
				flash[:error] = "Nice try h4x0r..."
				redirect_to :back
			end
		end
		
		# Post the message
		recipients = recipients.is_a?(Array) ? recipients : [recipients]
		if @micropost.recipient_type == 'group'
			@micropost.group_recipients = recipients
		elsif micropost.recipient_type == 'user'
			@micropost.user_recipients = recipients
		end
		
		if @micropost.save!
			flash[:success] = "The micropost was successfully created."
		else
			flash[:error] = "Please correct form errors."
		end
		
		respond_to do |format|
			format.js { render :controller => "microposts", :action => "create" } and return
		end
	end
	
	
	def destroy
		# verifies correct user
		if @micropost.destroy
			flash[:notice] = "The micropost was successfully deleted."
			redirect_to :back
		else
			flash[:error] = "The micropost deletion failed!"
			redirect_to :back
		end
	end
	
	def reload
		id = params[:id]
		type = params[:type]
		page = params[:microposts_paginate]
		page = 1 if @page==""
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true
		
		@user = nil
		@viewer = nil
		@micropost = nil
		if type == 'users'
			@user = User.find(id)
			@viewer = @user
			@micropost = @viewer.authored_posts.new
		elsif type == 'groups'
			@user = current_user
			@viewer = Group.find(id)
			@micropost = @user.authored_posts.new({:group_recipients => [@viewer]})
		else
			flash[:error] = "A viewing user or group was not defined."
			return "Error loading new data!"
		end
		
		@microposts = @viewer.all_received_posts.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 8)
		respond_to do |format|
			format.js { render :controller => "microposts", :action => "reload" }
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
end
