class PagesController < ApplicationController
  def home
  end

  def about
  end

  def publications
  end

  def screencasts
  end
  
  def tool_descriptions
  end

  def contact
    FeedbackMailer.send_feedback(params['contact_form']).deliver
    respond_to do |format|
      print format
      format.json { render :json => "Message Sent".to_json }
      format.html {} 
    end
  end
end
