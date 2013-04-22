class DatafilesController < ApplicationController
	before_filter :signed_in_user, :only => [:destroy, :reload]

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
