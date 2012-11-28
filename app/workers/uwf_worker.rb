require 'jobber'
require 'erb'

class UwfWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_ID, pheno_file, emma_type, snp_set, chromosome = -1, start_position = -1, stop_position = -1, bin_size = 1000000)

        ## ----------- Run EMMA -----------
        # Set the job location
        job_location    = File.join(DATA_path, job_ID)
        # Signal to redis that the configuration of emma has begun for this job
        $redis.sadd("#{job_ID}:progress:log",'config-emma')
        # Get the BerndtEmma configuration template
        config_template = File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')
        config_file     = File.join(job_location, 'BE.conf')
        # And populate it with the parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Signal to redis that an EMMA algorighm analysis has begun for this job and run it
        $redis.sadd("#{job_ID}:progress:log",'run-emma')
        cmd = "python #{EMMA_path}BerndtEmma.py -c #{config_file} -p #{job_location}"
        puts cmd
        system(cmd)
        # Comment out the line above and uncomment the line below to simulate an EMMA job run by just copying the results from another
        #FileUtils.cp('/raid/WWW/data/e38ff5/emmax_results.txt',job_location)
        ## ---------------------------------
        
        
        # Get the name of the result file for the circos plots 
        emma_result_file = job_location + '/' + emma_type + '_results.txt'
        
        
        ## ----------- Run Circos to make the full plot -----------
        # Get the path where plots should be saved, and create it
        job_location    = File.join(DATA_path, job_ID, 'Plots')
        Dir.mkdir(job_location)
        # Signal to redis that circos plot configuration has begun for this job
        $redis.sadd("#{job_ID}:progress:log",'config-circos')
        
        # Get the circos_generator configuration template 
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(job_location, 'CG.conf')
        # And populate it with the parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Signal to redis that the full genome Circos plot generation has begun, and run it
        $redis.sadd("#{job_ID}:progress:log",'run-circos')
        cmd = "python #{CIRCOS_path}circos_generator.py -p #{job_location}"
        puts cmd
        system(cmd)
        
        # Signal to redis we are now all done!
        $redis.set("#{job_ID}:finished", true)
        ##----------------------------------------------------------
        
=begin
        chr_sizes = [0, 197195432, 181748087, 159599783, 155630120, 152537259, 149517037, 152524553, 131738871, 124076172, 129993255, 121843856, 121257530, 120284312, 125194864,103494974, 98319150, 95272651, 90772031, 61342430, 166650296 ]
        # Set the slice size to 10,000,000. The circos generators have only been tested with this setting, but take other sizes
        slice_size = 1e7
        

        ## ----------- [Start Circos workers to cover 2 more levels] -----------
        ## ----------- Make directories for 2 more levels (images now requested on the fly  -----------
        for chromosome in (1..20)
            # Make the circos plot for this chromosome
            job_location = File.join(DATA_path, job_ID, "Plots/Chr#{chromosome}")
            # Uncomment the line below to generate level 2 plots (full chromosomes) with level 1 plot (full genome)
            #CircosWorker.perform_async(job_location, snp_set, emma_result_file, chromosome, -1, -1, 125000)
            # Make a list of slices and do a circos plot for each (now up to 400 plots)
            slices = (0..chr_sizes[chromosome]).step(slice_size).to_a << chr_sizes[chromosome]
            for i in (0..slices.length-2)
                start_pos = slices[i].to_i
                stop_pos = slices[i+1].to_i
                job_location = File.join(DATA_path, job_ID, "Plots/Chr#{chromosome}/#{start_pos}_#{stop_pos}")
                # Uncomment the line below to generate level 3 plots (full chromosomes) with level 1 plots (full genome)
                #CircosWorker.perform_async(job_location, snp_set, emma_result_file, chromosome, start_pos, stop_pos, 12500)
            end
        end
=end 
        
    end
end
