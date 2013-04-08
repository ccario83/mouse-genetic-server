require 'erb'

class CircosWorker
    
    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_location, snp_set, emma_result_file, chromosome = -1, start_position = -1, stop_position = -1, bin_size = 1000000)
        # job_ID is needed for a circos_generator subprocesses to communicate its progress to redis
        # -1 indicates the subprocess should to write progress to STDOUT instead
        # A job_ID is really only specified for the first circos plot (the full chomosome plot) because we want to indicate to the user some progress indication while they wait
        job_ID = -1
        # Make a directory for this job to write output to
        Dir.mkdir(job_location)
        
        # Load the circos_generator configuration file template, named 'GC.conf' and make it destined for the job directory
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(job_location, 'CG.conf')
        
        # Create the Circos config file with run parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Run the Circos Generator Script
        #puts "Circos running with job [#{job_location}, #{emma_result_file}, #{chromosome}, #{start_position}, #{stop_position}, #{bin_size}]"
        cmd = "python #{CIRCOS_PATH}circos_generator.py -p #{job_location}"
        system(cmd)
        
        # All done!
    end
end
