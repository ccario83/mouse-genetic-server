module UsersHelper

	# Returns the Gravatar for the given user.
	def gravatar_for(user, options = { :size => 50, } )
		gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
		size = options[:size]
		gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
		image_tag(gravatar_url, :alt => user.first_name, :class => "gravatar")
	end
	
	# Returns the Gravatar for the given user.
	def gravatar_edit_for(user)
		gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
		gravatar_url = "https://secure.gravatar.com/#{gravatar_id}"
		link_to("Change", gravatar_url)
	end
end
