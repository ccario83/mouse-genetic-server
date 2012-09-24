class MapController < ApplicationController

  respond_to :json, :html

  def index
    # Get all the resources
    @resources = Resource.where(:validated => 1)
    @json = @resources.to_gmaps4rails
    
    @new_resource = Resource.new
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @resources }
    end
  end
  
  def update
    @resource_types =  ActiveSupport::JSON.decode(params[:resource_types])
    puts @resource_types
    @resources = []
    Resource.where(:validated => 1).each do |resource|
        resource.resource_types.each do |res_type|
            puts res_type
            if @resource_types.include? res_type.name
                @resources << resource
            end
        end
    end
    if not @resources.empty?
        @resources = @resources.to_gmaps4rails
    end
    respond_with @resources
  end

  def create
    @resource = Resource.new(params[:resource])
    respond_to do |format|
      if @resource.save
        flash[:notice] = '<h3>Thank you!</h3>The resource was added for review.<br/>Check back later to see its posting.'.html_safe
        format.html { redirect_to "/map"}
        format.json { render json: @resource, status: :created }
      else
        format.html { render action: "/new" }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

end
