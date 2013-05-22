# app/controllers/static_controller.rb
class StaticController < ApplicationController
  before_filter :default_format_txt

  # Set format to xml unless client requires a specific format
  # Works on Rails 3.0.9
  def default_format_txt
    request.format = 'txt' unless params[:format]
  end


  def show
    begin
        file = File.open(File.join(USER_DATA_PATH, params[:path]+'.'+params[:format]))
    rescue Errno::ENOENT => e
        raise ActionController::RoutingError.new('Not Found')
    end
    respond_to do |format|
        format.svg { send_data(file.read, :type=>"image/svg+xml", :disposition =>"inline") and return }
        format.png { render :text => file.read and return }
        format.txt { send_file(file, :type=>"text/plain") and return }
    end
    send_file(file, :type=>"text/plain") 
    
  end

  def exists
    filename = File.join(USER_DATA_PATH, params[:path]+'.'+params[:format])
    if (FileTest.exists?(filename))
        render :json => { :status => true, }
    else
        render :json => { :status => false, }
    end
  end

end
