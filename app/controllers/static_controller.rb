# app/controllers/static_controller.rb
class StaticController < ApplicationController

  def show
    begin
        file = File.open(File.join(USER_DATA_PATH, params[:path]+'.'+params[:format]))
    rescue Errno::ENOENT => e
        raise ActionController::RoutingError.new('Not Found')
    end
    contents = file.read
    respond_to do |format|
        format.svg { send_data(contents, :type=>"image/svg+xml", :disposition =>"inline") }
        format.png { render :text => contents }
    end
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
