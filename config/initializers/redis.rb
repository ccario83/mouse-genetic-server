# Create a global $redis object for Redis communication
$redis = Redis.new(:host => 'localhost', :port => 6379)
