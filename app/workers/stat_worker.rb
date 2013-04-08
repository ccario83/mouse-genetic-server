require('rinruby')

class StatWorker
    include Sidekiq::Worker
    sidekiq_options retry: false
    
    # Define a class variable to store rinruby R connections
    @@myr = {}
    # The function takes an owner key job key, list of individual values, and corresponding list of strains as arguments
    def perform(owner_key, job_key, values, strains)
        # Create a new rinruby connection for this job
        @@myr[job_key] = RinRuby.new(echo = true, interactive = false)
        # Load the agricolae package
        @@myr[job_key].eval 'library(agricolae)'
        # Import the values and strains into the R namespace
        @@myr[job_key].assign 'values', values
        @@myr[job_key].assign 'strains', strains
        # Convert the data to the dataframe and perform a analysis of variance on it, using strain as a factor 
        @@myr[job_key].eval 'data = data.frame(values = values, strains = factor(strains))'
        @@myr[job_key].eval 'amod <- aov(data$values ~ data$strains ,data)'
        # Perform a Tukey HSD test on the model to find strain significance groupings
        @@myr[job_key].eval 'results <- HSD.test(amod, "data$strains")'
        # Pull out the relavant data from the results
        @@myr[job_key].eval 'strains <- as.vector(results$trt)'
        @@myr[job_key].eval 'means <- as.vector(results$means)'
        @@myr[job_key].eval 'stderrs <- as.vector(results$std.err)'
        @@myr[job_key].eval 'letters <- as.vector(results$M)'

        # Bring these results back into ruby
        @returned_strains = @@myr[job_key].pull 'strains'
        @returned_strains.map! { |x| x.rstrip() }
        @unsorted_means = @@myr[job_key].pull 'means'
        @unsorted_stderrs = @@myr[job_key].pull 'stderrs'
        @unsorted_letters = @@myr[job_key].pull 'letters'

        # Sort the strains and prepare variables with sorted values
        @strains = @returned_strains.sort
        @means = []
        @stderrs = []
        @letters = []
        
        # Sort all the corresponding values by strain
        @strains.each do |strain|
            idx = @returned_strains.index strain
            @means.push @unsorted_means[idx]
            @stderrs.push @unsorted_stderrs[idx].nan?? 0.0 : @unsorted_stderrs[idx]
            @letters.push @unsorted_letters[idx]
        end
        
        # Push the results to redis for this job job_key. This will allow the RoR AJAX handling action to access them.
        $redis.sadd("#{owner_key}:#{job_key}:strains",@strains.to_json)
        $redis.sadd("#{owner_key}:#{job_key}:means",@means.to_json)
        $redis.sadd("#{owner_key}:#{job_key}:stderrs",@stderrs.to_json)
        $redis.sadd("#{owner_key}:#{job_key}:letters",@letters.to_json)

        # Set this data to expire in around 10 minutes
        $redis.expire("#{owner_key}:#{job_key}:strains", 600)
        $redis.expire("#{owner_key}:#{job_key}:means", 600)
        $redis.expire("#{owner_key}:#{job_key}:stderrs", 600)
        $redis.expire("#{owner_key}:#{job_key}:letters", 600)
        $redis.expire("#{owner_key}:#{job_key}", 650)
        
        # Quit this R session and remove it from active R jobs
        @@myr[job_key].quit
        @@myr.delete(job_key)
    end
end
