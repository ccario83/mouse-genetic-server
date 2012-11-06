class PhenotypesController < ApplicationController
  def index
    redirect_to(:action => "show/")
  end


  def show
  end

  def lookup
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @results = Diagnosis.select(:mouse_id).where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    # Find all the mice with mpath and ma ids for the above
    
    
    # Render to lookup.html.erb
  end
end
