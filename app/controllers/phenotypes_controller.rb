require 'securerandom'
require 'jobber'

class PhenotypesController < ApplicationController
  def index
  end

  def test
    @mpath_id = 343;
    @anat_id = 2434;
    @all_strains = Mouse.joins(:strain).select(:name).map(&:name).uniq!.sort!
    @very_youngest = 201;
    @very_oldest = 1016;
  end

  def show
    @mpath_id = params['MPATH'].to_i
    @anat_id =  params['MA'].to_i

    if @mpath_id == 0
        @mapth_id = 458
    end

    @mice = Diagnosis.where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @mice = @mice.joins(:mouse => :strain).select('strains.name AS strain, age, code')
    @all_strains = Mouse.joins(:strain).select(:name).map(&:name).uniq!.sort!
    @very_youngest = @mice.minimum(:age)
    @very_oldest = @mice.maximum(:age)
    @all_codes = @mice.select(:code).map(&:code).uniq!

  end


  def query
    # Get the requested filters
    @mpath_id           = params['mpath'].to_i
    @anat_id            = params['anat'].to_i
    @selelected_strains = params['selected_strains']
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']

    @mice = Mouse.new
    # Filter mice first by age
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain
    
    
    # Update the filters based on results (code never changes)
    @strains = @mice.select(:name).map(&:name).sort
    @youngest = @mice.minimum(:age)
    @oldest = @mice.maximum(:age)
    if @mice.map(&:sex).uniq.length == 2
        @sex = 'B'
    end

    @severities = {}
    @frequencies = {}
    @mice.map(&:sex).uniq.each do |sex|
        # Get the mice ids for this sex
        @sexed_mice = @mice.where(:sex => sex)
        @sexed_strains = @sexed_mice.select(:name).map(&:name).sort
        @ids = @sexed_mice.map(&:id)
        
        # Get the scores for these mice after filtering by mpath/anat ids, 
        @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
        @scores.where(:mouse_id => @ids)
        # Make a hash mapping mouse id to score
        @scores = Hash[@scores.map { |s| [s.mouse_id, s.score] }]
        
        # Make a list of strain names pointing to empty lists
        @results = Hash[@sexed_strains.uniq.zip(@sexed_strains.uniq.map { |v| [] })]

        # This could maybe be done more efficiently
        # For each mouse falling in this age/sex selection, get the mpath/anat score or use 0
        @sexed_mice.each do |mouse|
            # Get this mouse's score
            @results[mouse.name].push(@scores[mouse.id].to_i)
        end
        
        # Generate severity and frequency values
        @severities[sex] = Hash[@results.map { |k,v| [k, v.sum/v.length.to_f] }]
        @frequencies[sex] = Hash[@results.map { |k,v| [k, (v.length-v.count(0))/v.length.to_f] }]
    end

    # Return the data to the client
    render :json => {:strains => @strains, :youngest => @youngest, :oldest => @oldest, :sex => @sex, :severities => @severities, :frequencies => @frequencies }.to_json
  end



  def submit
    # Get the requested filters
    @mpath_id           = params['mpath'].to_i
    @anat_id            = params['anat'].to_i
    @selelected_strains = JSON.parse(params['selected_strains'])
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']

    @mice = Mouse.new
    # Filter mice first by age
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain


    # Update the filters based on actual results
    @selected_strains = @mice.select(:name).map(&:name).uniq.sort
    #@youngest = @mice.minimum(:age)
    #@oldest = @mice.maximum(:age)
    #if @mice.map(&:sex).uniq.length == 2
    #    @sex = 'B'
    #end

    @results = Hash[@selected_strains.zip(@selected_strains.map { |v| [] })]

    # Get the mice ids for this sex
    @ids = @mice.map(&:id)
    # Get the scores for these mice after filtering by mpath/anat ids, 
    @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @scores.where(:mouse_id => @ids)
    # Make a hash mapping mouse id to score
    @scores = Hash[@scores.map { |s| [s.mouse_id, s.score] }]
    # Populate the results
    @mice.each do |mouse|
        # Get this mouse's score
        @results[mouse.name].push(@scores[mouse.id].to_i)
    end
    
    
    # Prepare the data for and start the StatWorker
    @job_id = SecureRandom.hex(3)
    @strains = []
    @values = []
    @results.each do |strain, strain_values|
        strain_values.each do |value|
            @strains.push(strain)
            @values.push(value)
        end 
    end
    StatWorker.perform_async(@job_id, @values, @strains)
    
    
    # For the view, calculate the frequencies and ns for each strain add a lookup table for friendlier sex descriptions
    @ns = Hash[@results.map { |k,v| [k, v.length] }]
    @frequencies = Hash[@results.map { |k,v| [k, (v.length-v.count(0))/v.length.to_f] }]
    @sex_long = {'B'=>'Male & Female', 'M' => 'Male', 'F' => 'Female' }
  end



  def check_stats
    @id = params['id']
    if !($redis.exists("#{@id}:letters"))
        render :json => { :status => 'Not ready.', :id => @id}.to_json
    else
        @strains = JSON.parse($redis.smembers("#{@id}:strains")[0]).map{ |x| x.rstrip! }
        @means   = JSON.parse($redis.smembers("#{@id}:means")[0])
        @stderrs = JSON.parse($redis.smembers("#{@id}:stderrs")[0])
        @letters = JSON.parse($redis.smembers("#{@id}:letters")[0])
        render :json => { :status => 'Ready.', :strains => @strains, :means => @means, :stderrs => @stderrs, :letters => @letters, :id => @id}.to_json
    end
  end



  def analyze
    # Get the requested filters
    @mpath_id           = params['mpath'].to_i
    @anat_id            = params['anat'].to_i
    @selected_strains   = params['selected_strains']
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']
    @measure            = params['measure']
    
    @selected_strains = JSON.parse(@selected_strains)
    
    @mice = Mouse.new
    # Filter mice first by age
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain
    
    
    # Update the filters based on actual results
    @selected_strains = @mice.select(:name).map(&:name).uniq.sort
    
    
    @results = Hash[@selected_strains.zip(@selected_strains.map { |v| [] })]
    # Get the mice ids for this sex
    @ids = @mice.map(&:id)
    # Get the scores for these mice after filtering by mpath/anat ids, 
    @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_id, :path_base_term_id => @mpath_id)
    @scores.where(:mouse_id => @ids)
    # Make a hash mapping mouse id to score
    @scores = Hash[@scores.map { |s| [s.mouse_id, s.score] }]
    # Populate the results
    @mice.each do |mouse|
        # Get this mouse's score
        @results[mouse.name].push(@scores[mouse.id].to_i)
    end
    @frequencies = Hash[@results.map { |k,v| [k, (v.length-v.count(0))/v.length.to_f] }]
    @severities = Hash[@results.map { |k,v| [k, v.sum/v.length.to_f] }]


    # Start a new UFW job using Jobber
    @job = Job.new('UWF')
    sex_long = { 'M'=>'male', 'F'=>'female', 'B'=>'NA' }
    @pheno_file = @job.location + '/pheno.txt'
    File.open(@pheno_file, 'w') do |pheno_file|
        if @measure == 'severity'
            pheno_file.printf "Strain\tAnimal_Id\tSex\tSeverity\n"
            # To do individual mice instead of averages
            #@mice.each do |mouse|
            #    pheno_file.printf "%s\t%d\t%s\t%.2f\n", mouse.name, mouse.id, sex_long[mouse.sex], @scores[mouse.id]
            #end
            @fake_id = 1
            @severities.each do |strain, value|
                pheno_file.printf "%s\t%d\t%s\t%.2f\n", strain, @fake_id, sex_long[@sex], value
                @fake_id = @fake_id + 1
            end
        else
            pheno_file.printf "Strain\tAnimal_Id\tSex\tFrequency\n"
            @fake_id = 1
            @frequencies.each do |strain, value|
                pheno_file.printf "%s\t%d\t%s\t%.2f\n", strain, @fake_id, sex_long[@sex], value
                @fake_id = @fake_id + 1
            end
        end    
    end
    # Save the variables into a serialized file in the job directory with Jobber
    @job.track_var('@pheno_file', binding)
    @job.save()

    # Set some parameters for the UWF view
    @new_job = false
    @job_name = PathBaseTerm.find(@mpath_id).term + " " + MouseAnatomyTerm.find(@anat_id).term + " " + @measure
    @job_id = @job.ID
    render :template => "uwf/index"
  end
  
  def create
    redirect_to "uwf/create"
  end
end
