require 'erb'

class CircosWorker
    
    include Sidekiq::Worker
    sidekiq_options queue: 'Circos'
    sidekiq_options retry: false
    
    def perform(job_ID, emma_type, snp_set, chromosome = -1, start_position = -1, stop_position = -1)

        job_location    = File.join(DATA_path, job_ID)
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(job_location, "CG.conf")
        
        emma_result_file = job_location + emma_type + '_results.txt'
        
        # Create the Circos config file with run parameters
        message = ERB.new(File.read(config_template))
        File.open(config_file, "w") { |f| f.write(message.result(binding)) }

        # Run the Circos Plot Generator
        puts "Circos running with job [#{job.ID}]"
        cmd = "python #{CIRCOS_path}circos_generator.py -g  #{config_file} -p #{job_location}"
        system(cmd)
        #puts cmd

        # All done!

    end
end
