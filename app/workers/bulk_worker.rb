require 'erb'

class BulkWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'BULK'
    sidekiq_options retry: false

    def perform(job_id)

        # Get the required parameters from the job ActiveRecord
        job = Job.find(job_id)
        job.state = 'Starting'
        job.save!
        emma_type = job.get_parameter('emma_type') 
        snp_set = job.get_parameter('snp_set')
        pheno_file = job.datafile.get_path
        job_location = job.directory
        job_key = job.redis_key
        owner_key = job.creator.redis_key
        redis_key = "#{owner_key}:#{job_key}"
        threads = job.get_parameter('threads')
        
        ## ----------- Push some redis keys -----------
        $redis.sadd   "#{redis_key}:progress:log","starting"
        $redis.expire "#{redis_key}:progress:log", 86400
        $redis.set    "#{redis_key}:completed", false
        $redis.expire "#{redis_key}:completed", 86400

        #job.state = 'Progressing'
        #job.save!
        ## ----------- Run EMMA -----------
        # Signal to redis that the configuration of emma has begun for this job
        $redis.sadd "#{redis_key}:progress:log",'starting bulk runner'

        # Signal to redis that an EMMA algorighm analysis has begun for this job and run it
        cmd = "python /bin/bulk.py -i #{pheno_file} -a #{emma_type} -s #{snp_set} -t #{threads}"
        puts cmd
        system(cmd)
        $redis.set    "#{redis_key}:completed", true
        job.state = 'Completed'
        job.save!
        # Comment out the line above and uncomment the line below to simulate an EMMA job run by just copying the results from another location
        
        if $redis.exists "#{redis_key}:error:log"
            job.state = 'Failed'
            job.save!
            return
        end
    end
end