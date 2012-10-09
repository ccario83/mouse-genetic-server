require 'erb'
class CircosWorker
    
    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_location, snp_set, emma_result_file, chromosome = -1, start_position = -1, stop_position = -1, bin_size = 1000000)
        
        job_ID = -1
        Dir.mkdir(job_location)
        
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(job_location, 'CG.conf')
        
        # Create the Circos config file with run parameters
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Run the Circos Plot Generator
        puts "Circos running with job [#{job_location}, #{emma_result_file}, #{chromosome}, #{start_position}, #{stop_position}, #{bin_size}]"
        cmd = "python #{CIRCOS_path}circos_generator.py -p #{job_location}"
        system(cmd)
        
        # All done!
    end
end
