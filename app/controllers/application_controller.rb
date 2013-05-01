class ApplicationController < ActionController::Base
	protect_from_forgery
	include SessionsHelper
	
	## REALLY UGLY CODE REQUIRED TO CLEAN UP IDS FROM FROMS WITH MULTISELECT
	def cleanup_ids(id_list)
		# The list is empty
		if (id_list=="[]" or id_list=="" or id_list==[""])
			id_list = []
		else
			begin
				# May be in JSON format
				id_list = JSON.parse(id_list).map(&:to_i)
			rescue
				# May not be
				id_list = id_list.map(&:to_i)
			end
			# Zero is never a valid ActiveRecord ID
			id_list.delete(0) if id_list.include?(0)
		end
		return id_list
	end
end
