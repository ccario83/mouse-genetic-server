class FeedbackMailer < ActionMailer::Base
  def send_feedback(contact_form)
      @params = contact_form
      mail(:to => "clc184@pitt.edu", :subject => "berndtlab.pitt.edu Feedback", :from => @params['email'])
  end
end
