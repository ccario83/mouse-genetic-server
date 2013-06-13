module SessionsHelper
	# Determines if the user is signed in via a browser cookie
	def sign_in(user)
		cookies.permanent[:remember_token] = user.remember_token
		# Calls the current_user=(user) method below. 'self' is needed so that Ruby knows current_user is a function call and not just a local variable
		self.current_user = user
	end

	# Returns true of false
	def signed_in?
		!current_user.nil?
	end

	# Signs out and deletes the browser cookie
	def sign_out
		self.current_user = nil
		cookies.delete(:remember_token)
	end

	# Sets the current user. This is like the default class variable 'read' function created by attr_accessor or attr_reader
	def current_user=(user)
		@current_user = user
	end

	# This is like the default class variable 'write' function created by attr_accessor or attr_writer except a lookup of the user occurs on each REQUEST
	def current_user
		@current_user ||= User.find_by_remember_token(cookies[:remember_token])
	end

	# Returns true or false
	def current_user?(user)
		user == current_user
	end

	# Returns true of false if the user is an administrator
	def is_admin?
		current_user.admin?
	end

	# Forces the user to sign in if required
	def signed_in_user
		unless signed_in?
			store_location
			redirect_to signin_path, :notice => "Please sign in."
		end
	end
	
	# Stores a user only page url until the user signs in
	def store_location
		session[:return_to] = request.fullpath
	end

	# Redirects back to the originally requested page or 'default'
	def redirect_back_or(default)
		redirect_to(session[:return_to] || default)
		session.delete(:return_to)
	end
end
