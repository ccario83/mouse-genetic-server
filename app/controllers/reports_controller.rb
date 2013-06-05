require 'securerandom'

class ReportsController < ApplicationController
  before_filter :admin_user

  def index
    redirect_to :action => :new
  end
  
  def new
    @user = current_user
    @job = @user.jobs.new
    @datafiles = @user.datafiles.where(:uwf_runnable => false)
    @job_name = "Enter a job name"
  end
  
  
  def create
    @user = current_user
    
    @job_name = params[:job][:name]

    @datafile = []
    if @user.datafiles.map(&:id).include?(params[:job][:datafile_id].to_i)
        @datafile = Datafile.find(params[:job][:datafile_id].to_i)
    else
        flash[:error] = "Nice try..."
         redirect_to :back
    end

    #Create the new job object
    @job = current_user.jobs.new(:name => @job_name, :runner => 'reports', :state => 'Starting', :parameters => params[:job][:parameters], :datafile => @datafile)
    @job.save!

    ReportsWorker.perform_async(@job.id)

    redirect_to "/users/#{@user.id}/jobs/#{@job.id}"
    return
  end
  
  
  def progress
    job = Job.find(params['id'])
    flanking_percent_complete = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:flanking-genes-progressbar")
    complete_percent_complete = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:complete-genes-progressbar")
    completed = $redis.get("#{current_user.redis_key}:#{job.redis_key}:completed")
    render :json => {flanking_complete: flanking_percent_complete, complete_complete: complete_percent_complete, completed: completed}.to_json
  end
  
  
  def generate

  end
  
  private
    def admin_user
        redirect_to root_path unless current_user.admin?
    end

end
