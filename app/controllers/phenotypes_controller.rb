class PhenotypesController < ApplicationController
  def index
    redirect_to(:action => "show/")
  end


  def show
  end

  def lookup
    @mpath_id = params['MPATH']
    @anat_id = 'MA:'+params['MA']
    
    # Find all the mice with mpath and ma ids for the above
    
    
    # Render to lookup.html.erb
  end
end
