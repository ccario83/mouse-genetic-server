# Clinton Cario
# 7/4/2013

class DatafilesController < ApplicationController
	before_filter :signed_in_user, :only => [:create, :destroy, :reload]
	before_filter :correct_user, :only => [:update, :destroy]

	def create
		# @user = User.find(params[:user_id]) # Less safe... can be faked. 
		# Assume the user is the signed in current user
		@user = current_user
		
		# Process new file based on the upload form paramater information
		@datafile = @user.datafiles.new()
		@datafile.process_uploaded_file(params[:datafile][:datafile])
		@datafile.description = params[:datafile][:description]
		@datafile.groups = Group.find(cleanup_ids(params[:datafile][:group_ids]))

		# Save the datafile and flash status
		if @datafile.save
			flash[:success] = "Datafile successfuly uploaded."
		else
			flash[:error] = "Please correct form errors."
		end
		
		# Respond via javascript (creating a datafile is an AJAX request)
		respond_to do |format|
			format.js { render :controller => "datafiles", :action => "create" } and return
		end
	end

	def update
		# Get the updated description and shared group list
		@datafile.description = params['datafile']['description']
		# cleanup_ids is found in app/controllers/application_controller.rb and takes the various list formats send by the browser and puts them into a simple Rails list object
		@datafile.groups = Group.find(cleanup_ids(params['datafile']['group_ids']))
		
		# Update the datafile parameters, and flah status
		if @datafile.save
			flash[:success] = "Datafile successfully updated."
		else
			flash[:error] = "Please correct form errors."
		end
		
		# Respond via javascript (again, an update is an AJAX request)
		respond_to do |format|
			format.js { render :controller => "datafiles", :action => "update" }
		end
	end

	# DELETE /user/:user_id/jobs/:id
	def destroy
		# Try to destroy and flash the status
		if @datafile.destroy
			flash[:success] = "The datafile was successfully deleted."
		else
			flash[:error] = "The datafile deletion failed!"
		end
		
		respond_to do |format|
			format.js { }
			format.html {  }
		end
	end

	# This function is used to reload the content of the datafiles-panel div
	def reload
		# Get the id (of the user or group)
		id = params[:id]
		# And the type of id ('users' or 'groups')
		type = params[:type]
		# Get the requested pagination page or default to 1
		page = params[:datafiles_paginate]
		page = 1 if @page==""
		# Determine if the AJAX request expects the div to be expanded upon return
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true

		# Define the user and viewer (either an user or group)
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
		
		# Get the datafiles owned by the user or shared with the group. (the viewer's datafiles)
		@datafiles = @viewer.datafiles.sort_by(&:created_at).reverse.paginate(:page => page, :per_page => 4)
		
		respond_to do |format|
			format.js { render :controller => "datafiles", :action => "reload" }
		end
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
