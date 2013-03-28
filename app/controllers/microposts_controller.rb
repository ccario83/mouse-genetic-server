class MicropostsController < ApplicationController
	before_filter :signed_in_user
	before_filter :correct_user, :only => :destroy
	before_filter :not_suspicious?, :only => [:create] # Verify hidden fields weren't altered


	def create
		@recipient_type = params[:micropost][:recipient_type]
		@content = params[:micropost][:content]

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


	private
		def correct_user
			@micropost = current_user.authored_posts.find_by_id(params[:id])
			if @micropost.nil?
				flash[:error] = "The micropost ownership verification failed!"
				redirect_to :back
			end
		end
		
		def not_suspicious?
			@recipient_type = params[:micropost][:recipient_type]
			
			@group_ids = []
			@user_ids = []
			if not (params[:micropost][:group_recipient_ids]=="[]")
				@group_ids = params[:micropost][:group_recipient_ids].split(',').map(&:to_i)
				@group_ids.delete(0) if @group_ids.include?(0)
			end
			if not (params[:micropost][:user_recipient_ids]=="[]")
				@user_ids = params[:micropost][:user_recipient_ids].split(',').map(&:to_i)
				@user_ids.delete(0) if @user_ids.include?(0)
			end
			
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
		end
end
