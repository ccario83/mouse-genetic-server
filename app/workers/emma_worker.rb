require 'erb'

class EmmaWorker
    
    include Sidekiq::Worker
    sidekiq_options queue: 'EMMA'
    sidekiq_options retry: false
    
    def perform(job_ID, pheno_file, emma_type, snp_set)
    
        job_location    = File.join(DATA_path, job_ID)
        config_template = File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')
        config_file     = File.join(job_location, "BE.conf")
        
        # Create a Berndt Emma config file with run parameters
        message = ERB.new(File.read(config_template))
        File.open(config_file, "w") { |f| f.write(message.result(binding)) }

        # Run the EMMA Job
        puts "EMMA running with job [#{job_ID}]"
        cmd = "python #{EMMA_path}BerndtEmma.py -c #{config_file} -p #{job_location}"
        system(cmd)
        #puts cmd

        # All done!

    end
end
