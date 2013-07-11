class ApplicationController < ActionController::Base
	protect_from_forgery
	include SessionsHelper
	
	# Some really ugly application wide code used to clean up IDs returned from HTML form elements like chosen
	def cleanup_ids(id_list)
		# The list is empty, which can happen 3 ways
		if (id_list=="[]" or id_list=="" or id_list==[""])
			id_list = []
		else
			begin
				# Maybe the list is in JSON format?
				id_list = JSON.parse(id_list).map(&:to_i)
			rescue
				# Maybe its not...
				id_list = id_list.map(&:to_i)
			end
			# Zero is never a valid ActiveRecord ID, may as well remove it
			id_list.delete(0) if id_list.include?(0)
		end
		return id_list
	end
end
