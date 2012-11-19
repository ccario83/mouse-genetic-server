require('rinruby')

class StatWorker
    include Sidekiq::Worker
    @@myr = {}
    def perform(id, values, strains)
        puts "Starting job for #{id}"
        @@myr[id] = RinRuby.new(echo = false, interactive = false)
        @@myr[id].eval 'library(agricolae)'
        @@myr[id].assign 'values', values
        @@myr[id].assign 'strains', strains
        @@myr[id].eval 'data = data.frame(values = values, strains = factor(strains))'
        @@myr[id].eval 'amod <- aov(data$values ~ data$strains ,data)'
        @@myr[id].eval 'results <- HSD.test(amod, "data$strains")'
        @@myr[id].eval 'letters <- as.vector(results$M)'
        results = @@myr[id].pull 'letters'
        $redis.sadd("#{id}:letters",results.to_json)
        $redis.expire("#{id}:letters", 60)
        $redis.expire("#{id}", 60)
        @@myr[id].quit
        @@myr.delete(id)
    end
end
