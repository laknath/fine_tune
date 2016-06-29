module FineTune
  class Base
    include Singleton

    class << self; attr_accessor :default_strategy, :adapter; end

    @@registry = {
      :leaky_bucket => ::FineTune::Strategies::LeakyBucket,
      :sliding_window => ::FineTune::Strategies::SlidingWindow
    }
    @default_strategy = ::FineTune::Strategies::LeakyBucket

    def throttle(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      count = strategy.increment(key, options)
      comp = strategy.compare?(count, options)

      yield(count, comp, key, strategy, options) if block_given?

      comp >= 0
    end

    def throttle!(name, id, options)
      block = Proc.new if block_given?

      throttle(name, id, options) do |count, comp, key, strategy, options|
        block.call(count, comp, key, strategy, options) if block

        raise MaxRateError.new(key, count, comp, strategy, options) if comp >= 0
      end
    end

    def rate_exceeded?(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      strategy.compare?(strategy.count(key, options), options) >= 0
    end

    def count(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      strategy.count(key, options)
    end

    def reset(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      strategy.reset(key, options)
    end

    def add_limit(name, options = {})
      limits[name] ||= {}
      limits[name].merge!(options)
    end

    def remove_limit(name)
      limits.delete(name)
    end

    def limits
      @limits ||= {}
    end

    private
    def current_strategy(name, id, options)
      options = (limits[name] || {}).merge(options)
      strategy = self.class.find_strategy(options[:strategy])

      if strategy.validate?(options)
        key = strategy.build_key(name, id, options)
      end

      raise "resource key undefined" unless key

      [strategy, key, options]
    end

    def self.find_strategy(strategy)
      registry.fetch(strategy, default_strategy).instance
    end

    def self.registry
      @@registry
    end
  end
end
