class PhenotypesController < ApplicationController
  def index
    redirect_to(:action => "show/")
  end


  def show
  end

  def lookup
    @mpath_id = params['mpath']
    @anat_id = params['anat']
    
    # Find all the mice with mpath and ma ids for the above
    
    
    # Render to lookup.html.erb
  end
end
