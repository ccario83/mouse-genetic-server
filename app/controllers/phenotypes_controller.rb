require 'securerandom'
require 'jobber'

class PhenotypesController < ApplicationController

  def index
    render "selector"
  end

  def selector
  end
  
  # The landing page after the phenotypes are selected
  def show
    @mpath_ids = JSON.parse(params['mpath_ids']).map! { |x| x.to_i }
    @anat_ids =  JSON.parse(params['anat_ids']).map! { |x| x.to_i }

    # Select the Diagnoses with this mpath/manat combination, join the mice strain names, ages, and codes
    @mice = Diagnosis.where(:mouse_anatomy_term_id => @anat_ids, :path_base_term_id => @mpath_ids)
    @mice = @mice.joins(:mouse => :strain).select('strains.name AS strain, age, code')
    if @mice.empty?
        flash[:notice] = "No Animals found with this combination. Please select again."
        render "selector"
    end
    # Get all the strain names, the minimum/maximum ages and all codes
    @all_strains = Mouse.joins(:strain).select(:name).map(&:name).uniq!.sort!
    @very_youngest = @mice.minimum(:age)
    @very_oldest = @mice.maximum(:age)
    @all_codes = @mice.select(:code).map(&:code).uniq!
    
  end
  
  
  
  # This is an AJAX JSON action to update page data when the user changes selections
  def query
    # Get the requested filters
    @mpath_id_list      = params['mpath_id_list'].map! { |x| x.to_i }
    @anat_id_list       = params['anat_id_list'].map! { |x| x.to_i }
    @selelected_strains = params['selected_strains']
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']


    # Filter mice first by age or code, if a code was selected
    @mice = Mouse.new
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then filter by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain??
    
    
    # Update the filters based on the actual results
    @strains = @mice.select(:name).map(&:name).sort
    @youngest = @mice.minimum(:age)
    @oldest = @mice.maximum(:age)
    if @mice.map(&:sex).uniq.length == 2
        @sex = 'B'
    end

    # Prepare severity and frequency arrays
    @ns = {}
    @severities = {}
    @frequencies = {}
    # For each sex
    @mice.map(&:sex).uniq.each do |sex|
        # Get the mice ids for this sex
        @sexed_mice = @mice.where(:sex => sex)
        @sexed_strains = @sexed_mice.select(:name).map(&:name).sort
        @ids = @sexed_mice.map(&:id)
        
        # Get the scores for these mice after filtering by mpath/anat ids, 
        @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_id_list, :path_base_term_id => @mpath_id_list)
        @scores.where(:mouse_id => @ids)
        # Make a hash mapping mouse id to score
        @scores = Hash[@scores.map { |s| [s.mouse_id, s.score] }]
        
        # Make a list of strain names pointing to empty lists
        @results = Hash[@sexed_strains.uniq.zip(@sexed_strains.uniq.map { |v| [] })]

        # For each mouse falling in this age/sex selection, get the mpath/anat score or use 0
        @sexed_mice.each do |mouse|
            # Get this mouse's score
            @results[mouse.name].push(@scores[mouse.id].to_i)
        end
        
        # Generate severity and frequency values
        @ns[sex] = Hash[@results.map { |k,v| [k, v.length] }]
        @severities[sex] = Hash[@results.map { |k,v| [k, v.sum/v.length.to_f] }]
        @frequencies[sex] = Hash[@results.map { |k,v| [k, (v.length-v.count(0))/v.length.to_f] }]
    end

    # Return the data to the client
    render :json => {:strains => @strains, :youngest => @youngest, :oldest => @oldest, :sex => @sex, :severities => @severities, :frequencies => @frequencies, :ns => @ns }.to_json
  end


  # This action is triggered when the user submits the phenotype selections
  def submit
    # Get the requested filters
    @mpath_ids          = JSON.parse(params['mpath_id_list']).map! { |x| x.to_i }
    @anat_ids           = JSON.parse(params['anat_id_list']).map! { |x| x.to_i }
    @selelected_strains = JSON.parse(params['selected_strains'])
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']

    # Filter mice first by age
    @mice = Mouse.new
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain??


    # Update the filters based on actual results
    @selected_strains = @mice.select(:name).map(&:name).uniq.sort
    #@youngest = @mice.minimum(:age)
    #@oldest = @mice.maximum(:age)
    #if @mice.map(&:sex).uniq.length == 2
    #    @sex = 'B'
    #end

    # Make a mapping of strain names to results (empty at the moment)
    @results = Hash[@selected_strains.zip(@selected_strains.map { |v| [] })]

    # Get the mice ids
    @ids = @mice.map(&:id)
    # Get the scores for these mice after filtering by mpath/anat ids, 
    @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_ids, :path_base_term_id => @mpath_ids)
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


  # This is an AJAX JSON action just checks if the stat worker is done and returns the values if it is
  def check_stats
    @id = params['id']
    if !($redis.exists("#{@id}:letters"))
        render :json => { :status => 'Not ready.', :id => @id}.to_json
    else
        @strains = $redis.smembers("#{@id}:strains")[0]
        @means   = $redis.smembers("#{@id}:means")[0]
        @stderrs = $redis.smembers("#{@id}:stderrs")[0]
        @letters = $redis.smembers("#{@id}:letters")[0]
        render :json => { :status => 'Ready.', :strains => @strains, :means => @means, :stderrs => @stderrs, :letters => @letters, :id => @id}.to_json
    end
  end


  # This action is triggered when the user accepts data on the stat page
  def analyze
    # Get the requested filters
    @mpath_id_list      = JSON.parse(params['mpath_id_list']).map! { |x| x.to_i }
    @anat_id_list       = JSON.parse(params['anat_id_list']).map! { |x| x.to_i }
    @selected_strains   = params['selected_strains']
    @youngest           = params['youngest'].to_i
    @oldest             = params['oldest'].to_i
    @code               = params['code']
    @sex                = params['sex']
    @measure            = params['measure']
    # Parse the list of selected strains
    @selected_strains = JSON.parse(@selected_strains)
    
    # Filter mice first by age
    @mice = Mouse.new
    if (@code == '')
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex]).where("age >= :youngest AND age <= :oldest", :youngest => @youngest, :oldest => @oldest)
    else
        @mice = Mouse.joins(:strain).select(['mice.id', :name, :age, :sex, :code]).where(:code => @code)
    end

    # Then filter by sex
    if not @sex == 'B'
        @mice = @mice.where(:sex => @sex)
    end
    
    # Eventually filter by strain??
    
    
    # Update the filters based on actual results
    @selected_strains = @mice.select(:name).map(&:name).uniq.sort
    
    # Make a mapping of strain names to results (empty at the moment)
    @results = Hash[@selected_strains.zip(@selected_strains.map { |v| [] })]
    # Get the mice ids
    @ids = @mice.map(&:id)
    # Get the scores for these mice after filtering by mpath/anat ids, 
    @scores = Diagnosis.select([:mouse_id, :score]).where(:mouse_anatomy_term_id => @anat_id_list, :path_base_term_id => @mpath_id_list)
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
    # Create a phenotype file called pheno.txt in the new job directory and populate it with the database data
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
    @job_name = PathBaseTerm.find(@mpath_id_list[0]).term + " " + MouseAnatomyTerm.find(@anat_id_list[0]).term + " " + @measure
    @job_id = @job.ID
    render :template => "uwf/index"
  end
  
  # Redirect UWF jobs generated by the phenotype explorer to the UWF create page
  def create
    redirect_to "uwf/create"
  end

  # AJAX to load phenotype selector tree data
  def get_mpath_tree
    @@mpath = File.read(File.join(Rails.root, 'public', 'mpath.json'))
    render :json => @@mpath
  end
  
    def get_anat_tree
    @@anat = File.read(File.join(Rails.root, 'public', 'anat.json'))
    render :json => @@anat
  end
  
end
