# a redis automatic failover solution

redis = RedisHa.new act as the same as redis = Redis.new

## for multi nodes redis (master + slaves)

``` ruby
  redis = RedisHa.new(:nodes => [
                                 {:host=>'master.redis', :port => 6379},
                                 {:host => 'slave1.redis',:port => 7379},
                                 {:host=>'slave2.redis', :port => 8379}])
  redis = RedisHa.new(:nodes => [
                                 {:host=>'master.redis', :port => 6379},
                                 {:host => 'slave1.redis',:port => 7379},
                                 {:host=>'slave2.redis', :port => 8379}],
                      :retry => :rotate,
                      :retry_interval => 30)
```

    :retry => :rotate,  means retry repeat on all nodes.
    :retry => :once, default :once, means retry on all nodes once only.

    `redis.ping`
    `redis.set :a, "a string"`
    `redis.keys`
