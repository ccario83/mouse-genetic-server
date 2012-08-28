require 'jobber'
require 'erb'

class UwfWorker
    EMMA_path = File.join(Rails.root, 'lib/EMMA/')
    CIRCOS_path = File.join(Rails.root, 'lib/Circos/')
    
    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_ID)
        job = restore_job(job_ID)
        pheno_file = job.get_path(job.tracked_vars['@pheno_file'])
        emma_type = job.tracked_vars['@emma_type']
        snp_set = job.tracked_vars['@snp_set']

        emma_result_file = job.location + emma_type + '_results.txt'
        chromosome = -1
        start_position = -1
        stop_position = -1

        # Create the berndt Emma config file
        message = ERB.new(File.read(File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')))
        File.open(File.join(job.location, "BE.conf"), "w") { |f| f.write(message.result(binding)) }

        # Create the berndt Circos config file
        message = ERB.new(File.read(File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')))
        File.open(File.join(job.location, "CG.conf"), "w") { |f| f.write(message.result(binding)) }

        # Run the EMMA Job
        print "UWF is starting an emma job [#{job.ID}]"
        cmd = "python #{EMMA_path}BerndtEmma.py -c #{job.location}/BE.conf -p #{job.location}"
        system(cmd)
        #puts cmd

        # Run the Circos Plot Generator
        print "UWF is starting an circos job [#{job.ID}]"
        cmd = "python #{CIRCOS_path}circos_generator.py -g  #{job.location}/CG.conf -p #{job.location}"
        system(cmd)
        #puts cmd
        
        # All done!

    end
end
