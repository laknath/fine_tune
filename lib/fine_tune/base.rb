module FineTune
  class Base
    include Singleton

    attr_accessor :adapter

    def throttle(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      count = strategy.increment(key, options)

      throttled = strategy.compare?(count, options)

      yield(count, key, strategy, options) if throttled && block_given?

      throttled
    end


    def throttle!(name, id, options)
      block = Proc.new if block_given?

      throttled(name, id, options) do |count, key, strategy, options|
        block.call(count, key, strategy, options) if block
        throw MaxRateError.new(key, count, strategy, options)
      end
    end

    def rate_exceeded?(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      strategy.compare?(strategy.count(key, options), options)
    end

    def add_limit(name, options = {})
      limits[name] ||= {}
      limits[name].merge!(options)
    end

    def remove_limit(name)
      limits.delete(name)
    end

    def reset(name, id)
      strategy, key, options = current_strategy(name, id, options)
      strategy.reset(key, options)
    end

    def count(name, id)
      strategy, key, options = current_strategy(name, id, options)
      strategy.count(key, options)
    end

    def limits
      @limits ||= {}
    end

    private
    def current_strategy(name, id, options)
      options = (limits[name] || {}).merge(options)
      strategy = ::FineTune::Strategies.Base.registry.fetch(options[:strategy],
                                        ::FineTune::Strategies.LeakyBucket)

      if strategy.validate?(options)
        key = strategy.build_key(name, id, options)
      end

      raise "resource key undefined" unless key

      [strategy, key, options]
    end
  end
end
