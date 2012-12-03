require('rinruby')

class StatWorker
    include Sidekiq::Worker
    sidekiq_options retry: false
    
    # Define a class variable to store rinruby R connections
    @@myr = {}
    # The function takes a job id, list of individual values, and corresponding list of strains as arguments
    def perform(id, values, strains)
        # Create a new rinruby connection for this job
        @@myr[id] = RinRuby.new(echo = true, interactive = false)
        # Load the agricolae package
        @@myr[id].eval 'library(agricolae)'
        # Import the values and strains into the R namespace
        @@myr[id].assign 'values', values
        @@myr[id].assign 'strains', strains
        # Convert the data to the dataframe and perform a analysis of variance on it, using strain as a factor 
        @@myr[id].eval 'data = data.frame(values = values, strains = factor(strains))'
        @@myr[id].eval 'amod <- aov(data$values ~ data$strains ,data)'
        # Perform a Tukey HSD test on the model to find strain significance groupings
        @@myr[id].eval 'results <- HSD.test(amod, "data$strains")'
        # Pull out the relavant data from the results
        @@myr[id].eval 'strains <- as.vector(results$trt)'
        @@myr[id].eval 'means <- as.vector(results$means)'
        @@myr[id].eval 'stderrs <- as.vector(results$std.err)'
        @@myr[id].eval 'letters <- as.vector(results$M)'

        # Bring these results back into ruby
        @returned_strains = @@myr[id].pull 'strains'
        @returned_strains.map! { |x| x.rstrip() }
        @unsorted_means = @@myr[id].pull 'means'
        @unsorted_stderrs = @@myr[id].pull 'stderrs'
        @unsorted_letters = @@myr[id].pull 'letters'

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
        
        # Push the results to redis for this job id. This will allow the RoR AJAX handling action to access them.
        $redis.sadd("#{id}:strains",@strains.to_json)
        $redis.sadd("#{id}:means",@means.to_json)
        $redis.sadd("#{id}:stderrs",@stderrs.to_json)
        $redis.sadd("#{id}:letters",@letters.to_json)

        # Set this data to expire in around 10 minutes
        $redis.expire("#{id}:strains", 600)
        $redis.expire("#{id}:means", 600)
        $redis.expire("#{id}:stderrs", 600)
        $redis.expire("#{id}:letters", 600)
        $redis.expire("#{id}", 650)
        
        # Quit this R session and remove it from active R jobs
        @@myr[id].quit
        @@myr.delete(id)
    end
end
