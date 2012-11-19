require 'securerandom'

class PhenotypesController < ApplicationController
  def index
  end

  def test
    @mpath_id = 343;
    @anat_id = 2434;
    @all_strains = ["AKR/J", "SJL/J", "C57BLKS/J", "BALB/cByJ", "C57L/J", "129S1/SvImJ", "LP/J", "P/J", "C57BL/6J", "NZO/H1LtJ", "SM/J", "BUB/BnJ", "C57BL/10J", "PWD/PhJ", "SWR/J", "NON/ShiLtJ", "NOD.B10Sn-H2<b>/J", "PL/J", "C57BR/cdJ", "A/J", "MRL/MpJ", "FVB/NJ", "CBA/J", "DBA/2J", "NZW/LacJ", "BTBR T<+> tf/J", "KK/HlJ", "WSB/EiJ"];
    @very_youngest = 201;
    @very_oldest = 1016;
  end

  def show
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @results = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @mice = @results.joins(:mouse => :strain).select('strains.name AS strain, age, code')
    @all_strains = []
    @all_ages = []
    @all_codes = []
    @mice.each do |mouse|
        @all_strains.push(mouse.strain)
        @all_ages.push(mouse.age)
        @all_codes.push(mouse.code)
    end
    @all_strains.uniq!
    @very_youngest = @all_ages.min
    @very_oldest = @all_ages.max
    @all_codes.uniq!
  end


  def query
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i
    
    @youngest = params['youngest'].to_i
    @oldest = params['oldest'].to_i
    @code = params['code']
    @sex = params['sex']
    @strains = params['selected_strains'].split(",")
    
    @results = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @results = @results.joins(:mouse => :strain).select('mouse_id, strains.name AS strain, age, sex, score')
    # Filter by age if required
    if (@code != '')
        @results = @results.where("code = :code", :code => @code)
    else
        @results = @results.where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    end
    # Filter by sex, if required
    if not @sex == "B"
        @results = @results.where("sex = :sex", :sex => @sex)
    end
    
    # Do filtering by strain here if this is ever required (also required implementation on the javascript layer)
    
    render :json => @results.to_json
  end
  
  
  def stats
    @values = params['values'].collect{|i| i.to_i}
    @strains = params['strains']
    @id = SecureRandom.hex(3)
    StatWorker.perform_async(@id, @values, @strains)
    render :json => "#{@id}".to_json
  end
  
  def check_stats
    @id = params['id']
    if !($redis.exists("#{@id}:letters"))
        render :json => { :status => 'Not ready.', :data => '', :id => @id}.to_json
    else
        @data = $redis.smembers("#{@id}:letters")[0]
        render :json => { :status => 'Ready.', :data => @data, :id => @id}.to_json
    end
  end
  
end
