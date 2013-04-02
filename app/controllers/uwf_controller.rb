#require 'jobber'

class UwfController < ApplicationController

  def index
    @new_job = true
    @job_name = "Enter a job name"
  end

  def create
    # Get the form data
    @pheno_file = params['uwf_submit']['pheno_file']
    @emma_type = params['uwf_submit']['emma_type']
    @snp_set = params['uwf_submit']['snp_set']
    @job_id = params['uwf_submit']['job_id']

    # If a job ID has been embedded on the page, the phenotype exporer was used to generate a phenotype file, use this file instead of one from the user
    @job = nil
    if @job_id.is_a? NilClass
        # Start a new UFW job using Jobber
        @job = Job.new('UWF')
        # Process the uploaded file and get it's path
        @pheno_file = @job.process_uploaded_file(@pheno_file)
        # Save the variables into a serialized file in the job directory with Jobber
        @job.track_var('@pheno_file', binding)
    else
        @job = restore_job(@job_id)
        @pheno_file = @job.tracked_vars['@pheno_file']
    end

    @job.track_var('@emma_type', binding)
    @job.track_var('@snp_set', binding)
    @job.save()
    
    # Use sidekiq to start the job, communicate to redis stati about this job
    $redis.sadd("#{@job.ID}:progress:log","started")
    $redis.set("#{@job.ID}:finished", false)
    $redis.expire("#{@job.ID}:progress:log", 86400)
    $redis.expire("#{@job.ID}:finished", 86400)
    UwfWorker.perform_async(@job.ID, @pheno_file, @emma_type, @snp_set)
    
    redirect_to(:action => "show/#{@job.ID}")
  end
  
  def show
    # Get the id of the job to show
    @job_ID = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    
    # Remember the parameters of the job with Jobber
    @job = restore_job(@job_ID)
    @pheno_file = File.basename(@job.tracked_vars['@pheno_file'])
    @emma_type = @job.tracked_vars['@emma_type']
    @snp_set = @job.tracked_vars['@snp_set']
    
    # Check if the job is finished and pass the state to the view
    @ready = $redis.get("#{@job_ID}:finished") == "true"
    # Also display the circos plot thumbnail if it is ready
    if @ready
        @circos_thumb = File.join('/data/', @job_ID, "/Plots/circos.png")
    end
  end
  
  def progress
    @job_ID = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    @log = $redis.smembers("#{@job_ID}:progress:log")
    @ready = $redis.get("#{@job_ID}:finished") == "true"
    if @ready
        render :json => "finished"
    else
        render :json => @log.to_json
    end
  end

  def generate
    # Get the job id and remember the parameters from this job with Jobber
    @job_ID = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    @job = restore_job(@job_ID)
    @emma_type = @job.tracked_vars['@emma_type']
    @snp_set = @job.tracked_vars['@snp_set']
    @emma_result_file = File.join(DATA_path, @job_ID,'/' + @emma_type + '_results.txt')
    
    # Get the requested image tag and figure out which region to show
    @image_tag = params['image_tag']
    @chromosome = @image_tag.split("_")[0]
    @start_pos = @image_tag.split("_")[1]
    @stop_pos = @image_tag.split("_")[2]

    # Density is how many points should be placed on the Circos plot. This sets the default vlaue for the CircosWorker
    @density = 12500
    
    # Determine the job location (which subfolder to place the image, organized by chromosome)
    @job_location = ''
    # A -1 start and stop position signifies the full chromosome should be shown
    if (@start_pos == '-1' and @stop_pos == '-1')
        @job_location = File.join(DATA_path, @job_ID, "Plots/Chr#{@chromosome}")
        # Change the default density for the full chromosome plot
        @density = 125000
    else
        # Within the chromosome folder, sub plots are stored in start_pos_stop_pos folders
        @job_location = File.join(DATA_path, @job_ID, "Plots/Chr#{@chromosome}/#{@start_pos}_#{@stop_pos}")
    end

    # Ask the CircosWorker to create this plot
    CircosWorker.perform_async(@job_location, @snp_set, @emma_result_file, @chromosome, @start_pos, @stop_pos, @density)
    render :json => "Ok! Job started!"
  end

end
