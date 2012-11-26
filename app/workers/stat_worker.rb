require('rinruby')

class StatWorker
    include Sidekiq::Worker
    sidekiq_options retry: false
    
    @@myr = {}
    def perform(id, values, strains)
        @@myr[id] = RinRuby.new(echo = true, interactive = false)
        @@myr[id].eval 'library(agricolae)'
        @@myr[id].assign 'values', values
        @@myr[id].assign 'strains', strains
        @@myr[id].eval 'data = data.frame(values = values, strains = factor(strains))'
        @@myr[id].eval 'amod <- aov(data$values ~ data$strains ,data)'
        @@myr[id].eval 'results <- HSD.test(amod, "data$strains")'
        @@myr[id].eval 'strains <- as.vector(results$trt)'
        @@myr[id].eval 'means <- as.vector(results$means)'
        @@myr[id].eval 'stderrs <- as.vector(results$std.err)'
        @@myr[id].eval 'letters <- as.vector(results$M)'

        @returned_strains = @@myr[id].pull 'strains'
        @unsorted_means = @@myr[id].pull 'means'
        @unsorted_stderrs = @@myr[id].pull 'stderrs'
        @unsorted_letters = @@myr[id].pull 'letters'

        @strains = @returned_strains.sort
        @means = []
        @stderrs = []
        @letters = []
        
        @strains.each do |strain|
            idx = @returned_strains.index strain
            @means.push @unsorted_means[idx]
            @stderrs.push @unsorted_stderrs[idx]
            @letters.push @unsorted_letters[idx]
        end
        
        $redis.sadd("#{id}:strains",@strains.to_json)
        $redis.sadd("#{id}:means",@means.to_json)
        $redis.sadd("#{id}:stderrs",@stderrs.to_json)
        $redis.sadd("#{id}:letters",@letters.to_json)

        $redis.expire("#{id}:strains", 60)
        $redis.expire("#{id}:means", 60)
        $redis.expire("#{id}:stedrrs", 60)
        $redis.expire("#{id}:letters", 60)
        $redis.expire("#{id}", 65)
        
        @@myr[id].quit
        @@myr.delete(id)
    end
end
