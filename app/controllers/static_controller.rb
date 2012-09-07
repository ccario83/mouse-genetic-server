# app/controllers/static_controller.rb
class StaticController < ApplicationController
  
  def show
    send_file File.join(DATA_path, params[:path])
  end
  
end
