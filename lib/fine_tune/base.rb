#
# FineTune::Base provides a set of public methods and helpers to throttle
# and fetch the event count through a singleton object. The mechanism used to
# throttle and event counting is delegated to the defined strategy.
#
# Strategies can be defined for the entire library through 
# FineTune.default_strategy=. Strategy can also be defined for each 
# throttling call by passing <tt>:strategy</tt> option.
#
# Additionally, the datastore used to maintain event counts can be
# also customized by setting FineTune.adapter=. It takes an 
# ActiveSupport::Cache::Store[http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html] 
# as an adapter.

module FineTune
  class Base
    include Singleton

    class << self; 
      # Used to set a strategy for all calls.
      attr_accessor :default_strategy

      # Used to set the external data store.
      attr_accessor :adapter

      def registry
        @@registry
      end

      def find_strategy(strategy)
        registry.fetch(strategy, default_strategy).instance
      end
    end

    # Currently supported strategies:
    # * Leaky bucket algorithm
    @@registry = {
      :leaky_bucket => ::FineTune::Strategies::LeakyBucket,
      :sliding_window => ::FineTune::Strategies::SlidingWindow
    }
    @default_strategy = ::FineTune::Strategies::LeakyBucket

    # Calling throttle represents an occurance of an event.
    # Depends on the strategy used for the actual calculations.
    # Returns true if the event should be throttled.
    #
    # ==== Attributes
    #
    # * +name+ - Name of the rule ie: emails_sent
    # * +id+ - Identifier for a specific resource ie: abc@example.com
    # * +options+ - Options for the strategy. Depends on the strategy choosen
    #
    # ==== Options
    #
    # * +:strategy+ - The strategy chosen. Valid options are:
    #   - leaky_bucket
    #
    # Optionally, a block can be passed and it will be called with 
    # calculated values
    #
    # ==== Examples
    #   FineTune.throttle(:emails_sent, "abc@example.com",
    #     {strategy: :leaky_bucket}) do |count, comparison, key, strategy, options|
    #       # some calculation ...
    #     end

    def throttle(name, id, options)
      strategy, key, options = current_strategy(name, id, options)
      count = strategy.increment(key, options)
      comp = strategy.compare?(count, options)

      yield(count, comp, key, strategy, options) if block_given?

      comp >= 0
    end

    # The more forceful variant of throttle. Will raise a MaxRateError if the 
    # defined threshold is exceeded.
    #
    # Attributes and options are same as for +throttle+.

    def throttle!(name, id, options)
      throttle(name, id, options) do |count, comp, key, strategy, options|
        yield count, comp, key, strategy, options if block_given?

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
  end
end
