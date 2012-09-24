# app/controllers/static_controller.rb
class StaticController < ApplicationController
  
  def show
    send_file File.join(DATA_path, params[:path])
  end
  
  def svg
    file = File.open(File.join(DATA_path, params[:path]), "rb")
    contents = file.read
    respond_to do |format|  
        format.svg { contents }
    end
  end
end
