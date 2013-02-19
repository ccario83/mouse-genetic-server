module SessionsHelper
	
	def sign_in(user)
		cookies.permanent[:remember_token] = user.remember_token
		self.current_user = user  # Calls the current_user=(user) method below 'self'+ is needed so that Ruby knows this is a function call and not just a local variable
	end

	def signed_in?
		!current_user.nil?
	end

	def sign_out
		self.current_user = nil
		cookies.delete(:remember_token)
	end

	def current_user=(user)  # This is the default class variable read function created by attr_accessor or attr_reader
		@current_user = user
	end

	def current_user  # This is like the default class variable write function created by attr_accessor or attr_writer except a lookup of the user occurs on each REQUEST
		@current_user ||= User.find_by_remember_token(cookies[:remember_token])
	end

	def current_user?(user)
		user == current_user
	end

	def is_admin?
		current_user.admin?
	end

	def store_location
		session[:return_to] = request.fullpath
	end

	def redirect_back_or(default)
		redirect_to(session[:return_to] || default)
		session.delete(:return_to)
	end

	def signed_in_user
		unless signed_in?
			store_location
			redirect_to signin_path, :notice => "Please sign in."
		end
	end
end
