require 'jobber'
require 'erb'

class UwfWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_ID, pheno_file, emma_type, snp_set, chromosome = -1, start_position = -1, stop_position = -1)

        job_location    = File.join(DATA_path, job_ID)

        ## ----------- Run EMMA -----------
        $redis.sadd("#{job_ID}:progress:log","config-emma")
        config_template = File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')
        config_file     = File.join(job_location, "BE.conf")
        
        # Create a Berndt Emma config file with run parameters
        message = ERB.new(File.read(config_template))
        File.open(config_file, "w") { |f| f.write(message.result(binding)) }

        # Run the EMMA Job
        $redis.sadd("#{job_ID}:progress:log","run-emma")
        cmd = "python #{EMMA_path}BerndtEmma.py -c #{config_file} -p #{job_location}"
        system(cmd)
        
        
        ## ----------- Run Circos -----------
        $redis.sadd("#{job_ID}:progress:log","config-circos")
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(job_location, "CG.conf")
        
        emma_result_file = job_location + '/' + emma_type + '_results.txt'
        
        # Create the Circos config file with run parameters
        message = ERB.new(File.read(config_template))
        File.open(config_file, "w") { |f| f.write(message.result(binding)) }

        # Run the Circos Plot Generator
        $redis.sadd("#{job_ID}:progress:log","run-circos")
        cmd = "python #{CIRCOS_path}circos_generator.py -g  #{config_file} -p #{job_location}"
        system(cmd)
        
        # All done!
        $redis.set("#{job_ID}:finished", true)
    end
end
