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
      # Used to set a default strategy for all calls.
      attr_accessor :default_strategy

      # Used to set the external data store.
      attr_accessor :adapter

      def registry #:nodoc:
        @@registry
      end

      def find_strategy(strategy) #:nodoc:
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

    def throttle(name, id, options = {})
      options[:validate] = true
      strategy, key, options = current_strategy(name, id, options)
      count = strategy.increment(key, options)
      comp = strategy.compare?(count, options)

      yield(count, comp, key, strategy, options) if block_given?

      comp >= 0
    end

    # The more forceful variant of throttle. Will raise a MaxRateError if the 
    # defined threshold is exceeds.
    #
    # Attributes and options are same as for +throttle+.

    def throttle!(name, id, options = {})
      throttle(name, id, options) do |count, comp, key, strategy, opts|
        yield count, comp, key, strategy, opts if block_given?

        raise MaxRateError.new(key, count, comp, strategy, opts) if comp >= 0
      end
    end

    # Returns true if current count exceeds the given limits.
    #
    # Attributes and options are same as for +throttle+.
    def rate_exceeded?(name, id, options = {})
      strategy, key, options = current_strategy(name, id, options)
      strategy.compare?(strategy.count(key, options), options) >= 0
    end

    # Returns the current event count.
    #
    # Attributes and options are same as for +throttle+.
    def count(name, id, options = {})
      strategy, key, options = current_strategy(name, id, options)
      strategy.count(key, options)
    end

    # Resets the counter for the given resource identifer to 0.
    #
    # Attributes and options are same as for +throttle+.
    def reset(name, id, options = {})
      strategy, key, options = current_strategy(name, id, options)
      strategy.reset(key, options)
    end

    # Adds a preconfigured rule and options to the rule. These configs 
    # can be overridden by passing different option values later when
    # calling +throttle+.
    #
    # ==== Attributes
    #
    # * +name+ - Name of the rule ie: emails_sent
    # * +options+ - Default options for the rule
    #
    # ==== Examples
    #   FineTune.add_limit(:emails_sent_per_hour, {window: 3600})
    #
    def add_limit(name, options = {})
      limits[name] ||= {}
      limits[name].merge!(options)
    end

    # Removes a preconfigured rule and options.
    def remove_limit(name)
      limits.delete(name)
    end

    # Returns all default limits defined
    def limits
      @limits ||= {}
    end

    private
    def current_strategy(name, id, options) #:nodoc:
      options = (limits[name] || {}).merge(options)
      strategy = self.class.find_strategy(options[:strategy])

      if !options.delete(:validate) || strategy.validate?(options)
        key = strategy.build_key(name, id, options)
      end

      raise "resource key undefined" unless key

      [strategy, key, options]
    end
  end
end
