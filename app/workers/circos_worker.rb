require 'erb'

class CircosWorker
    
    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_ID, location, chromosome = -1, start_position = -1, stop_position = -1, bin_size = 5000000)
        job = Job.find(job_ID)
        # job_ID is needed for a circos_generator subprocesses to communicate its progress to redis
        # -1 indicates the subprocess should to write progress to STDOUT instead
        # A job_ID is really only specified for the first circos plot (the full chomosome plot) because we want to indicate to the user some progress indication while they wait
        job_ID = -1
        job_key = job.redis_key
        owner_key = job.creator.redis_key
        
        # Declare other variables in the config file
        #redis_key = "#{owner_key}:#{job_key}" # NOT NEEDED FOR SUB IMAGES
        emma_result_file = job.resultfile
        # chromosome     = defined during method call
        # start_position = defined during method call
        # stop_position  = defined during method call
        # bin_size       = defined during method call
        snp_set          = job.get_parameter('snp_set')
        
        # Make a directory for this job to write output to
        Dir.mkdir(location) unless File.exists?(location)
        
        # Determine paths for the circos_generator configuration file template ('GC.conf') and its destination
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(location, 'CG.conf')
        
        # Create the Circos config file with run parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Run the Circos Generator Script
        #puts "Circos running with job [#{job.id} #{location}, #{job.resultfile}, #{chromosome}, #{start_position}, #{stop_position}, #{bin_size}]"
        cmd = "python #{CIRCOS_PATH}circos_generator.py -p #{location}"
        puts cmd
        system(cmd)
        
        redis_key = "#{owner_key}:#{job_key}"
        $redis.sadd "#{redis_key}:ready_images:","#{chromosome}_#{start_position}_#{stop_position}"
        # All done!
    end
end