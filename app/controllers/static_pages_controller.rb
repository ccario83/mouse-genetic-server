class StaticPagesController < ApplicationController
	def home
	# signed_in is defined in app/sessions/session_helper.rb
	if signed_in?
		redirect_to "/users/#{current_user.id}"
	end
	end

	# By default renders app/views/static_pages/about.html.erb
	def about
	end

	def publications
	end

	def screencasts
	end

	def tool_descriptions
	end

	# Handles the Contact form submit
	def contact
		# This is defined in app/mailers/feedback_mailer.eb
		FeedbackMailer.send_feedback(params['contact_form']).deliver
		respond_to do |format|
			print format
			format.json { render :json => "Message Sent".to_json }
			format.html {}
		end
	end
end
