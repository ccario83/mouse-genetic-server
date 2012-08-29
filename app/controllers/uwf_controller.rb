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
    job = Job.new('UWF')
    
    # Process the uploaded file and get it's path
    @pheno_file = job.process_uploaded_file(@pheno_file)
    
    # Save the variables into a serialized file in the job directory
    job.track_var('@pheno_file', binding)
    job.track_var('@emma_type', binding)
    job.track_var('@snp_set', binding)
    job.save()
    
    $redis.sadd("#{job.ID}:progress:log","Started")
    UwfWorker.perform_async(job.ID, @pheno_file, @emma_type, @snp_set)
    # Use sidekiq to start the job
    
    redirect_to(:action => "show/#{job.ID}")
  end
  
  def show
    @job_id = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    @ready = false
  end
  
  def progress
    @job_id = params['id'] # id is what comes after the slash in 'uwf/show/#' by default
    @log = $redis.smembers("#{@job_id}:progress:log")
    render :json => @log.to_json
  end

end
