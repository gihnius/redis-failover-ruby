
require 'redis'

class RedisHa

  ## a redis automatic failover solution

  ## redis = RedisHa.new act as the same as redis = Redis.new
  ## for multi nodes redis (master + slaves)

  # redis = RedisHa.new(:nodes => [
  #                                {:host=>'master.redis', :port => 6379},
  #                                {:host => 'slave1.redis',:port => 7379},
  #                                {:host=>'slave2.redis', :port => 8379}])
  # redis = RedisHa.new(:nodes => [
  #                                {:host=>'master.redis', :port => 6379},
  #                                {:host => 'slave1.redis',:port => 7379},
  #                                {:host=>'slave2.redis', :port => 8379}],
  #                     :retry => :rotate,
  #                     :retry_interval => 30)

  ## :retry => :once, default :once, means retry on all nodes once only,
  ## :retry => :rotate means repeat on all nodes.

  ## redis.ping
  ## redis.set :a, "a string"
  ## redis.keys

  def initialize(opts={})
    @nodes = opts.delete(:nodes) || [ {:host => '127.0.0.1', :port => 6379} ]
    @retry_link = opts.delete(:retry) || :once
    @retry_link_interval = opts.delete(:retry_interval) || 15
    @nodes_left = @nodes.dup
    @next_node = {}
    @redis = nil
    @config = opts
    setup_new_redis
  end

  ## proxy Redis instance
  def method_missing(method, *args)
    if @redis && @redis.respond_to?(method)
      retry_redis_count = @nodes.size
      begin
        if args
          res = @redis.send(method, *args)
        else
          res = @redis.send(method)
        end
      rescue Redis::CannotConnectError
        setup_new_redis
        retry_redis_count -= 1
        retry if retry_redis_count > 0
      end
    else
      puts "Error: No method #{method} for #{@reids}!"
    end
  end


private

  def setup_new_redis
    if @nodes_left.size == 0
      if @retry_link == :rotate
        @nodes_left = @nodes.dup
        sleep @retry_link_interval
      elsif @retry_link == :once
        puts "Error: No more nodes to try! Set :retry => :rotate to repeat."
        return
      end
    end
    @next_node = @nodes_left.shift
    puts "Setting up redis connection from server: #{@next_node}"
    @config.merge!(@next_node)
    @redis = Redis.new(@config)
    if @redis
      begin
        @redis.ping
      rescue Redis::CannotConnectError
        puts "Error: Can not setup connection to redis server #{@next_node}!"
      end
    end
  end

end
