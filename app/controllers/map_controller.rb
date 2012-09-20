class MapController < ApplicationController
  def index
    @resources = Resource.all
    @resource_types = ResourceType.pluck(:resource_type).uniq
    @json = Resource.all.to_gmaps4rails
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
  
  def update
    @resources = Resource.all
    @json = Resource.all.to_gmaps4rails
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
  
  def create
    puts params[:new_resource]['name']
    if params[:new_resource]

    end
    @resources = Resource.new(params[:new_resource])

    respond_to do |format|
      if @resources.save
        format.html { redirect_to @resources, notice: 'Character was successfully created.' }
        format.json { render json: @resources, status: :created, location: @resources }
      else
        format.html { render action: "new" }
        format.json { render json: @resources.errors, status: :unprocessable_entity }
      end
    end
  end
end
