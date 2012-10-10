require 'jobber'

class UwfController < ApplicationController

  def new
    render('index')
  end


  def create
    # Get the form data
    @pheno_file = params['uwf_submit']['pheno_file']
    @emma_type = params['uwf_submit']['emma_type']
    @snp_set = params['uwf_submit']['snp_set']

    # Start a new UFW job
    @job = Job.new('UWF')
    
    # Process the uploaded file and get it's path
    @pheno_file = @job.process_uploaded_file(@pheno_file)
    
    # Save the variables into a serialized file in the job directory
    @job.track_var('@pheno_file', binding)
    @job.track_var('@emma_type', binding)
    @job.track_var('@snp_set', binding)
    @job.save()
    
    # Use sidekiq to start the job
    $redis.sadd("#{@job.ID}:progress:log","started")
    $redis.set("#{@job.ID}:finished", false)
    $redis.expire("#{@job.ID}:progress:log", 86400)
    $redis.expire("#{@job.ID}:finished", 86400)
    UwfWorker.perform_async(@job.ID, @pheno_file, @emma_type, @snp_set)
    
    redirect_to(:action => "show/#{@job.ID}")
  end
  
  def show
    @job_ID = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    
    @job = restore_job(@job_ID)
    @pheno_file = File.basename(@job.tracked_vars['@pheno_file'])
    @emma_type = @job.tracked_vars['@emma_type']
    @snp_set = @job.tracked_vars['@snp_set']
    
    @ready = $redis.get("#{@job_ID}:finished") == "true"
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
    @job_ID = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    @job = restore_job(@job_ID)
    @emma_type = @job.tracked_vars['@emma_type']
    @snp_set = @job.tracked_vars['@snp_set']
    @emma_result_file = File.join(DATA_path, @job_ID,'/' + @emma_type + '_results.txt')
    
    @image_tag = params['image_tag']
    @chromosome = @image_tag.split("_")[0]
    @start_pos = @image_tag.split("_")[1]
    @stop_pos = @image_tag.split("_")[2]
    
    @job_location = ''
    @density = 12500
    if (@start_pos == '-1' and @stop_pos == '-1')
        @job_location = File.join(DATA_path, @job_ID, "Plots/Chr#{@chromosome}")
        @density = 125000
    else
        @job_location = File.join(DATA_path, @job_ID, "Plots/Chr#{@chromosome}/#{@start_pos}_#{@stop_pos}")
    end

    CircosWorker.perform_async(@job_location, @snp_set, @emma_result_file, @chromosome, @start_pos, @stop_pos, @density)
    render :json => "Ok! Job started!"
  end

end
