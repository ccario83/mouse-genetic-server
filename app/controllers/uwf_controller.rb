class UwfController < ApplicationController
  before_filter :signed_in_user, :only => [:index, :new, :create, :progress, :generate]

  def index
    redirect_to :action => :new
  end
  
  def new
    @user = current_user
    @enable_file_selection = true
    @job = @user.jobs.new
    @datafiles = @user.datafiles.where(:uwf_runnable => true)
    @job_name = "Enter a job name"
  end
  
  
  def create
    @user = current_user
    
    @job_name = params[:job][:name]
    @emma_type = params[:job][:parameters][:emma_type]
    @snp_set = params[:job][:parameters][:snp_set]
    @job_description = params[:job][:description]

    @datafile = []
    if @user.datafiles.map(&:id).include?(params[:job][:datafile_id].to_i)
        @datafile = Datafile.find(params[:job][:datafile_id].to_i)
    else
        flash[:error] = "Nice try..."
         redirect_to :back
    end

    # Create the new job object
    image_parameters = { "-1_-1_-1" => { chromosome: -1, start_pos: -1, stop_pos: -1, bin_size: 5000000 } }
    @job = current_user.jobs.new(:name        => @job_name,         \
                                 :description => @job_description,  \
                                 :runner      => 'UWF',             \
                                 :state       => 'Starting',        \
                                 :datafile    => @datafile,         \
                                 :parameters  => {  :image_parameters   => image_parameters,            \
                                                    :emma_type          => @emma_type,                  \
                                                    :snp_set            => @snp_set                     \
                                                 }
                                )
    @job.save!

    UwfWorker.perform_async(@job.id)

    redirect_to "/users/#{@user.id}/jobs/#{@job.id}"
    return
  end
  
  
  def progress
    job = Job.find(params['id'])
    log = $redis.smembers("#{current_user.redis_key}:#{job.redis_key}:progress:log")
    errors = $redis.smembers("#{current_user.redis_key}:#{job.redis_key}:error:log")
    render :json => {log: log, errors: errors}.to_json
  end
  
  
  def generate
    # Get the job id and remember the parameters from this job with Jobber
    job = Job.find(params['id'])
    
    # Get the requested image tag and figure out which region to show
    image_tag  = params['image_tag']
    chromosome = image_tag.split("_")[0].to_i
    start_pos  = image_tag.split("_")[1].to_i
    stop_pos   = image_tag.split("_")[2].to_i

    # Density is how many points should be placed on the Circos plot. This sets the default vlaue for the CircosWorker
    density = 12500
    
    # A -1 start and stop position signifies the full chromosome should be shown
    dirctory = ''
    if (start_pos == -1 and stop_pos == -1)
        directory = File.join(job.directory, "Plots/Chr#{chromosome}")
        # Change the default density for the full chromosome plot
        density = 125000
    else
        # Within the chromosome folder, sub plots are stored in start_pos_stop_pos folders
        directory = File.join(job.directory, "Plots/Chr#{chromosome}/#{start_pos}_#{stop_pos}")
    end

    image_parameters = { image_tag => { chromosome: chromosome, start_pos: start_pos, stop_pos: stop_pos, bin_size: 5000000, density: density, directory: directory } }
    params = job.get_parameter('image_parameters')
    params ||= {}
    params.merge!(image_parameters)
    job.store_parameters(params)

    # Ask the CircosWorker to create this plot
    CircosWorker.perform_async(job.id, directory, chromosome, start_pos, stop_pos, density)
    
    render :json => "Ok! Job started!"
  end
  
  def get_circos_panel
    image_tag = params['image_tag']
    @image_path = params['image_path']
    @job = Job.find(params['job_id'])
    @params = @job.get_parameter('image_parameters')[image_tag]
    respond_to do |format|
        format.html { render :partial => "circos_panel" }
    end
  end

end
