class UwfController < ApplicationController
  before_filter :signed_in_user, :only => [:index, :new, :create, :progress, :generate]

  def index
    redirect_to :action => :new
  end
  
  def new
    @enabled_upload = true
    @job = current_user.jobs.new
    @datafile = Datafile.new
    @job_name = "Enter a job name"
  end
  
  
  def create
    # Get the form data
    if params['job']['datafile'].has_key?(:id)
        id = params['job']['datafile']['id'].to_i
        if current_user.datafiles.map(&:id).include?(id)
            params['job']['datafile'] = Datafile.find(id)
        else
            flash[:error] = "Nice try..."
            redirect_to :back
        end
    else
        # Process new file
        datafile = current_user.datafiles.new()
        datafile.process_uploaded_file(params['job']['datafile'])
        datafile.save!
        params['job']['datafile'] = datafile
    end

    # Create the new job object
    @job = current_user.jobs.new(params['job'])
    # Set the runner
    @job.runner = 'UWF'
    @job.save!

    UwfWorker.perform_async(@job.id)

    redirect_to '/users/#{current_user.id}/jobs/#{@job.id}'
    return
  end
  
  
  def progress
    @job = Job.find(params['id'])
    @log = $redis.smembers("#{current_user.redis_key}:#{@job.redis_key}:progress:log")
    render :json => @log.to_json
  end
  
  
  def generate
    # Get the job id and remember the parameters from this job with Jobber
    @job = Job.find(params['id'])
    @emma_type = @job.get_parameter('emma_type')
    @snp_set = @job.get_parameter('snp_set')
    @emma_result_file = File.join(@job.datafile.get_path, @emma_type + '_results.txt')
    
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
        @job_location = File.join(@job.directory, "Plots/Chr#{@chromosome}")
        # Change the default density for the full chromosome plot
        @density = 125000
    else
        # Within the chromosome folder, sub plots are stored in start_pos_stop_pos folders
        @job_location = File.join(@job.directory, "Plots/Chr#{@chromosome}/#{@start_pos}_#{@stop_pos}")
    end

    # Ask the CircosWorker to create this plot
    CircosWorker.perform_async(@job_location, @snp_set, @emma_result_file, @chromosome, @start_pos, @stop_pos, @density)
    render :json => "Ok! Job started!"
  end

end
