class PhenotypesController < ApplicationController
  def index
  end

  def show
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @results = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @mice = @results.joins(:mouse => :strain).select('strains.name AS strain, age')
    @all_strains = []
    @all_ages = []
    @mice.each do |mouse|
        @all_strains.push(mouse.strain)
        @all_ages.push(mouse.age)
    end
    @all_strains.uniq!
    @very_youngest = @all_ages.min
    @very_oldest = @all_ages.max
  end


  def query
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @youngest = params['youngest'].to_i
    @oldest = params['oldest'].to_i
    @sex = params['sex']
    @strains = params['selected_strains'].split(",")
    
    @results = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @results = @results.joins(:mouse => :strain).select('mouse_id, strains.name AS strain, age, sex, score')
    # Filter by age if required
    @results = @results.where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    # Filter by sex, if required
    if not @sex == "B"
        @results = @results.where("sex = :sex", :sex => @sex)
    end
    
    # Do filtering by strain here if this is ever required (also required implementation on the javascript layer)
    
    render :json => @results.to_json
  end
end
