require('rinruby')

class StatWorker
    include Sidekiq::Worker
    sidekiq_options retry: false
    
    @@myr = {}
    def perform(id, values, strains)
        @@myr[id] = RinRuby.new(echo = false, interactive = false)
        @@myr[id].eval 'library(agricolae)'
        @@myr[id].assign 'values', values
        @@myr[id].assign 'strains', strains
        @@myr[id].eval 'data = data.frame(values = values, strains = factor(strains))'
        @@myr[id].eval 'amod <- aov(data$values ~ data$strains ,data)'
        @@myr[id].eval 'results <- HSD.test(amod, "data$strains")'
        @@myr[id].eval 'letters <- as.vector(results$M)'
        @@myr[id].eval 'strains <- as.vector(results$trt)'
        @results = @@myr[id].pull 'letters'
        @returned_strains = @@myr[id].pull 'strains'
        @ordered_results = []
        @returned_strains.sort.each do |strain|
            idx = @returned_strains.index strain
            @ordered_results.push @results[idx]
        end
        $redis.sadd("#{id}:letters",@ordered_results.to_json)
        $redis.expire("#{id}:letters", 60)
        $redis.expire("#{id}", 60)
        @@myr[id].quit
        @@myr.delete(id)
    end
end
