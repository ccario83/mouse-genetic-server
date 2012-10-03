require 'jobber'
require 'erb'

class UwfWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(@job_ID, @pheno_file, @emma_type, @snp_set, @chromosome = -1, @start_position = -1, @stop_position = -1)

        ## ----------- Run EMMA -----------
        @job_location    = File.join(DATA_path, @job_ID)
        $redis.sadd('#{job_ID}:progress:log','config-emma')
        @config_template = File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')
        @config_file     = File.join(job_location, 'BE.conf')
        
        # Create a Berndt Emma config file with run parameters
        @config = ERB.new(File.read(@config_template))
        File.open(@config_file, 'w') { |f| f.write(@config.result(binding)) }

        # Run the EMMA Job
        $redis.sadd('#{job_ID}:progress:log','run-emma')
        @cmd = 'python #{EMMA_path}BerndtEmma.py -c #{config_file} -p #{job_location}'
        system(@cmd)
        ## ---------------------------------
        
        
        # Get the name of the result file for the circos plots 
        @emma_result_file = @job_location + '/' + @emma_type + '_results.txt'
        
        
        ## ----------- Run Circos to make the full plot -----------
        @job_location    = File.join(DATA_path, @job_ID, 'Plots')
        $redis.sadd('#{job_ID}:progress:log','config-circos')
        
        @config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        @config_file     = File.join(@job_location, 'CG.conf')
        
        # Create the Circos config file with run parameters
        @config = ERB.new(File.read(@config_template))
        File.open(@config_file, 'w') { |f| f.write(@config.result(binding)) }

        # Run the Circos Plot Generator
        $redis.sadd('#{job_ID}:progress:log','run-circos')
        @cmd = 'python #{CIRCOS_path}circos_generator.py -p #{job_location}'
        system(@cmd)
        
        # All done!
        $redis.set('#{job_ID}:finished', true)
        ##----------------------------------------------------------
        
        
        @chr_sizes = [0, 197195432, 181748087, 159599783, 155630120, 152537259, 149517037, 152524553, 131738871, 124076172, 129993255, 121843856, 121257530, 120284312, 125194864,103494974, 98319150, 95272651, 90772031, 61342430, 166650296 ]
        # Set the slice size to 10,000,000. The circos generators have only been tested with this setting, but take other sizes
        SLICE_SIZE = 1e7
        
        
        ## ----------- Start Circos workers to cover 2 more levels -----------
        for @chromosome in (1..20)
            # Make the circos plot for this chromosome
            @job_location = File.join(DATA_path, @job_ID, 'Plots/Chr%s'%@chromosome)
            CircosWorker.perform_async(@job_location, @emma_results_file, @chromosome)
            # Make a list of slices and do a circos plot for each (now up to 400 plots)
            @slices = (SLICE_SIZE..@chr_sizes[@chromosome]).step(SLICE_SIZE).to_a << @chr_sizes[@chromosome]
            @slices.each do |@slice|
                @job_location = File.join(DATA_path, @job_ID, 'Plots/Chr%s_%s_%s'%(@chromosome, @slice-SLICE_SIZE, @slice))
                CircosWorker.perform_async(@job_location, @emma_results_file, @chromosome, @slice-SLICE_SIZE, @slice)
            end
        end
        
        
    end
end
