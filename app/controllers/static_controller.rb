# app/controllers/static_controller.rb
class StaticController < ApplicationController

  def show
    file = File.open(File.join(DATA_path, params[:path]+'.'+params[:format]))
    contents = file.read
    respond_to do |format|
        format.svg { send_data(contents, :type=>"image/svg+xml", :disposition =>"inline") }
        format.png { render :text => contents }
    end
  end

end
