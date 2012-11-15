require('rinruby')

class StatWorker

    include Sidekiq::Worker
    sidekiq_options retry: false
    
    def perform(id, values, strains)
        R.eval 'library(agricolae)'
        R.assign 'values', values
        R.assign 'strains', strains
        R.eval 'data = data.frame(values = values, strains = factor(strains))'
        R.eval 'amod <- aov(data$values ~ data$strains ,data)'
        R.eval 'results <- HSD.test(amod, "data$strains")'
        R.eval 'letters <- as.vector(results$M)'
        results = R.pull 'letters'
        $redis.sadd("#{id}:letters",results.to_json)
        $redis.expire("#{id}:letters", 60)
        $redis.expire("#{id}", 60)
    end
end
