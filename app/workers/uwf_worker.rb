require 'erb'

class UwfWorker

    include Sidekiq::Worker
    sidekiq_options queue: 'UWF'
    sidekiq_options retry: false
    
    def perform(job_id, chromosome = -1, start_position = -1, stop_position = -1, bin_size = 5000000)
        
        
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
        
        ## ----------- Push some redis keys -----------
        $redis.sadd   "#{redis_key}:progress:log","starting"
        $redis.expire "#{redis_key}:progress:log", 86400
        $redis.set    "#{redis_key}:completed", false
        $redis.expire "#{redis_key}:completed", 86400
        
        # Set the additional parameters in the job's ActiveRecord
        job.state = 'Progressing'
        job.save!
        
        
        ## ----------- Run EMMA -----------
        # Signal to redis that the configuration of emma has begun for this job
        $redis.sadd "#{redis_key}:progress:log",'configuring-gwa'
        
        # Declare other variables in the config file
        # snp_set        = defined above
        # pheno_file     = defined above
        # emma_type      = defined above
        # redis_key      = defined above

        # Determine paths for the BerndtEmma configuration file template ('BE.conf') and its destination
        config_template = File.join(Rails.root,'app/views/uwf/BE_conf_template.erb')
        config_file     = File.join(job_location, 'BE.conf')
        
        # Create the BerndtEmma config file with run parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }

        # Signal to redis that an EMMA algorighm analysis has begun for this job and run it
        $redis.sadd "#{redis_key}:progress:log",'starting-gwa'
        cmd = "python #{EMMA_PATH}BerndtEmma.py -c #{config_file} -p #{job_location}"
        puts cmd
        system(cmd)
        # Comment out the line above and uncomment the line below to simulate an EMMA job run by just copying the results from another location
        #FileUtils.cp('/raid/WWW/data/e38ff5/emmax_results.txt',job_location)
        ## ---------------------------------
        
        
        if $redis.exists "#{redis_key}:error:log"
            job.state = 'Failed'
            job.save!
            return
        end
        
        # Get the name of the result file for the circos plots, add it as a resultfile to the job. 
        result_filename  = emma_type + '_results.txt'
        result_directory = job_location
        job.resultfile   = File.join(result_directory, result_filename)
        # Create this as a datafile for the user
        datafile = job.creator.datafiles.new({:filename => result_filename, :directory => result_directory, :description => "Result for #{job.redis_key}" })
        datafile.save!
        
        ## ----------- Run Circos to make the full plot -----------
        # Signal to redis that circos plot configuration has begun for this job
        $redis.sadd "#{redis_key}:progress:log",'configuring-circos'
        
        # Declare other variables in the config file
        # redis_key      = defined above
        emma_result_file = job.resultfile
        # chromosome     = defined during method call
        # start_position = defined during method call
        # stop_position  = defined during method call
        # bin_size       = defined during method call
        # snp_set        = defined during method call
        
        # Get the path where plots should be saved, and create it
        location    = File.join(job_location, 'Plots')
        # Make a directory for this job to write output to
        Dir.mkdir(location)
        
        # Determine paths for the circos_generator configuration file template ('GC.conf') and its destination
        config_template = File.join(Rails.root,'app/views/uwf/CG_conf_template.erb')
        config_file     = File.join(location, 'CG.conf')
        
        # Create the Circos config file with run parameters passed to this function
        config = ERB.new(File.read(config_template))
        File.open(config_file, 'w') { |f| f.write(config.result(binding)) }


        # Signal to redis that the full genome Circos plot generation has begun, and run it
        $redis.sadd "#{redis_key}:progress:log",'starting-circos'
        cmd = "python #{CIRCOS_PATH}circos_generator.py -p #{location}"
        puts cmd
        system(cmd)
        
        if $redis.exists "#{redis_key}:error:log"
            job.state = 'Failed'
            job.save!
            return
        end
        
        
        # Signal to redis we are now all done!
        $redis.sadd "#{redis_key}:progress:log",'completed'
        $redis.set "#{redis_key}:completed", true
        $redis.sadd "#{redis_key}:ready_images",'-1_-1_-1'
        job.state = 'Completed'
        job.store_parameter({circos_root_url: File.join('/data', job.creator.redis_key, 'jobs', job.redis_key, 'Plots')})
        job.save!
        
    end
end

##----------------------------------------------------------
=begin
        chr_sizes = [0, 197195432, 181748087, 159599783, 155630120, 152537259, 149517037, 152524553, 131738871, 124076172, 129993255, 121843856, 121257530, 120284312, 125194864,103494974, 98319150, 95272651, 90772031, 61342430, 166650296 ]
        # Set the slice size to 10,000,000. The circos generators have only been tested with this setting, but take other sizes
        slice_size = 1e7
        

        ## ----------- [Start Circos workers to cover 2 more levels] -----------
        ## ----------- Make directories for 2 more levels (images now requested on the fly  -----------
        for chromosome in (1..20)
            # Make the circos plot for this chromosome
            job_location = File.join(job_location, "Plots/Chr#{chromosome}")
            # Uncomment the line below to generate level 2 plots (full chromosomes) with level 1 plot (full genome)
            #CircosWorker.perform_async(job_location, snp_set, emma_result_file, chromosome, -1, -1, 125000)
            # Make a list of slices and do a circos plot for each (now up to 400 plots)
            slices = (0..chr_sizes[chromosome]).step(slice_size).to_a << chr_sizes[chromosome]
            for i in (0..slices.length-2)
                start_pos = slices[i].to_i
                stop_pos = slices[i+1].to_i
                job_location = File.join(job_location, "Plots/Chr#{chromosome}/#{start_pos}_#{stop_pos}")
                # Uncomment the line below to generate level 3 plots (full chromosomes) with level 1 plots (full genome)
                #CircosWorker.perform_async(job_location, snp_set, datafile.get_path, chromosome, start_pos, stop_pos, 12500)
            end
        end
=end 
