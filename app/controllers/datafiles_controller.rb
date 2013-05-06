class DatafilesController < ApplicationController
	before_filter :signed_in_user, :only => [:create, :destroy, :reload]
	before_filter :correct_user, :only => :destroy

	def create
		@user = current_user
		# @user = User.find(params[:user_id]) # Less safe... can be faked. 
		# Process new file

		@datafile = @user.datafiles.new()
		@datafile.process_uploaded_file(params[:datafile][:datafile])
		@datafile.description = params[:datafile][:description]
		@datafile.groups = Group.find(cleanup_ids(params[:datafile][:group_ids]))

		if @datafile.save
			flash[:notice] = "Datafile uploaded."
		else
			flash[:error] = "Please correct form errors."
		end
		
		respond_to do |format|
			format.js { render :controller => "datafiles", :action => "create" } and return
		end
	end

	def update
		@datafile = Datafile.find(params[:id])
		@datafile.description = params['datafile']['description']
		@datafile.groups = Group.find(cleanup_ids(params['datafile']['group_ids']))
		
		if @datafile.save
			flash[:success] = "Datafile successfully updated."
		else
			flash[:error] = "Please correct form errors."
		end
		
		respond_to do |format|
			format.js { render :controller => "datafiles", :action => "update" }
		end
	end

	def destroy
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

	def reload
		id = params[:id]
		type = params[:type]
		page = params[:datafiles_paginate]
		page = 1 if @page==""
		@show_listing_on_load = (params.has_key? :expand) ? params[:expand]=="true" : true

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
