class DatafilesController < ApplicationController
	before_filter :signed_in_user, :only => [:create, :destroy, :reload]

	def create
		@user = current_user
		# Process new file
		@datafile = @user.datafiles.new()
		@datafile.process_uploaded_file(params['datafile']['datafile'])
		@datafile.description = params['datafile']['description']
		if @datafile.save!
			flash[:notice] = "Profile updated"
		else
			flash[:error] = @datafile.errors
		end

		render :partial => 'users/datafile_form', :locals => { user: @user, datafile: @datafile }
	end

	def destroy
		
	end

	def reload
		@user = params[:user_id]
		page = params[:datafiles_paginate]
		@user ||= current_user
		page = 1 if page==""
		@datafiles = @user.datafiles.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 4)
		render :partial => 'shared/datafile_panel', :locals => { viewer: @user, show_listing_on_load: true }
	end

end
