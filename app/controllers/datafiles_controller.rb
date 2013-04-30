class DatafilesController < ApplicationController
	before_filter :signed_in_user, :only => [:create, :destroy, :reload]
	before_filter :correct_user, :only => :destroy

	def create
		@user = current_user
		# Process new file
		@datafile = @user.datafiles.new()
		@datafile.process_uploaded_file(params['datafile']['datafile'])
		@datafile.description = params['datafile']['description']
		if @datafile.save!
			flash[:notice] = "Datafile uploaded"
		else
			flash[:error] = @datafile.errors
		end

		render :partial => 'users/datafile_form', :locals => { user: @user, datafile: @datafile }
	end

	def destroy
		if @datafile.destroy
			flash[:notice] = "The datafile was successfully deleted."
			redirect_to :back
		else
			flash[:error] = "The datafile deletion failed!"
			redirect_to :back
		end
		
		#respond_to do |format|
		#	format.js { }
		#	format.html {  }
		#end
	end

	def reload
		id = params[:id]
		type = params[:type]
		page = params[:datafiles_paginate]
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
		
		@datafiles = @user.datafiles.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 4)
		render :partial => 'shared/datafile_panel', :locals => { viewer: @user, show_listing_on_load: true }
	end

	private
		def correct_user
			#current_user = params[:user_id] # DONT TRUST
			@datafile = current_user.datafiles.find_by_id(params[:id])
			if @datafile.nil?
				flash[:error] = "The datafile ownership verification failed!"
				redirect_to :back
			end
		end
end
