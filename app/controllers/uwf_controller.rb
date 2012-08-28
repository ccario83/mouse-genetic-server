class UwfController < ApplicationController

  def new
    render('index')
  end


  def create
    # Get the form data
    @pheno_file = params['uwf_submit']['pheno_file']
    @emma_type = params['uwf_submit']['emma_type']
    @snp_set = params['uwf_submit']['snp_set']

    # Get jobber to handle the upload file and remember the parameters 
    require 'jobber'
    job = Job.new('UWF')
    
    job.process_uploaded_file(@pheno_file)
    @pheno_file = @pheno_file.original_filename
    
    job.track_var('@pheno_file', binding)
    job.track_var('@emma_type', binding)
    job.track_var('@snp_set', binding)
    
    job.save()
    
    UwfWorker.perform_async(job.ID)
    # Use sidekiq to start the job
    
    render('submit')
  end
  

  
end
