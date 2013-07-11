# Coded by: Matt Richardson

require 'securerandom'

class BulkController < ApplicationController
  before_filter :admin_user

  def index
    redirect_to :action => :new
  end
  
  def new
    @user = current_user
    @enable_file_selection = true
    @job = @user.jobs.new
    @datafiles = @user.datafiles.where(:uwf_runnable => false)
    @job_name = "Enter a job name"
  end
  
  
  def create
    @user = current_user
    
    @job_name = params[:job][:name]
    @emma_type = params[:job][:parameters][:emma_type]
    @snp_set = params[:job][:parameters][:snp_set]
    @threads = params[:job][:parameters][:threads]
    
    @datafile = []
    if @user.datafiles.map(&:id).include?(params[:job][:datafile_id].to_i)
        @datafile = Datafile.find(params[:job][:datafile_id].to_i)
    else
        flash[:error] = "Nice try..."
         redirect_to :back
    end

    #Create the new job object
    @job = current_user.jobs.new(:name => @job_name, :runner => 'BULK', :state => 'Starting', :parameters => params[:job][:parameters], :datafile => @datafile)
    @job.save!

    BulkWorker.perform_async(@job.id)

    redirect_to "/users/#{@user.id}/jobs/#{@job.id}"
    return
  end
  
  
  def progress
    job = Job.find(params['id'])
    gwas_started = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:gwas_started")
    gwas_completed = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:gwas_completed")
    manhattan_started = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:manhattan_started")
    manhattan_completed = $redis.get("#{current_user.redis_key}:#{job.redis_key}:progress:manhattan_completed")

    completed = $redis.get("#{current_user.redis_key}:#{job.redis_key}:completed")
    render :json => { gwas_started:  gwas_started,  gwas_completed:  gwas_completed, manhattan_started: manhattan_started, manhattan_completed: manhattan_completed, completed: completed}.to_json
  end
  
  
  def generate

  end
  
  private
    def admin_user
        redirect_to root_path unless current_user.admin?
    end

end
