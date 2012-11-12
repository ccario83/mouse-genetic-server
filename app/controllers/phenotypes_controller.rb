class PhenotypesController < ApplicationController
  def index
  end

  def show
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
  end
  
  def query
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @youngest = params['youngest'].to_i
    @oldest = params['oldest'].to_i
    @sex = params['sex']
    
    @results = Diagnosis.select("mouse_id, score").where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    # Find all the mice with mpath and ma ids for the above
    
    
    @results = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @results = @results.joins(:mouse => :strain).select('mouse_id, strains.name AS strain, age, sex, score')
    # Filter by age if required
    @results = @results.where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    # Filter by sex, if required
    if not @sex == "B"
        @results = @results.where("sex = :sex", :sex => @sex)
    end
    
    render :json => @results.to_json
  end
end
