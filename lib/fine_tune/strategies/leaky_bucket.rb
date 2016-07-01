module FineTune
  module Strategies

    # Implements {LeakyBucket algorithm}[https://en.wikipedia.org/wiki/Leaky_bucket]
    # as a FineTune::Strategy.
    class LeakyBucket < Base

      class << self
        # Set default values for window, average and maximum values so
        # they won't need to be passed in every call
        attr_accessor :default_window, :default_average, :default_maximum
      end

      # compares the count given and the burst value.
      # Returns 0 if equal, -1 less and 1 greater
      #
      # ====== Attributes
      #
      # * +count+ - the current count
      # * +options+ - Optional if default_maximum is set
      #
      # ====== Options
      # * +:maximum - can be used to override default_maximum
      def compare?(count, options)
        count <=> maximum(options)
      end

      # Returns the current count incremented by one if it does not exceed the 
      # maximum value given. If it exceeds the maximum value, then it returns
      # the maximum value.
      #
      # ====== Attributes
      #
      # * +key+ - the identifier for the resource in cache store
      # * +options+ - Optional if default_maximum, default_window and default_average set
      #
      # ====== Options
      # * +:maximum+ - can be used to override default_maximum ie: 20
      # * +:average+ - can be used to override default_average ie: 10
      # * +:window+ - can be used to override default_window  ie: 3600 (one hour)
      def increment(key, options)
        count = count(key, options)
        count = [maximum(options), count + 1].min
        adapter.write(key, {count: count, timestamp: Time.now.to_i})
        count
      end

      # Returns the current count after discounting for the time since
      # last access.
      #
      # Attributes and options are same as +increment+
      def count(key, options)
        resource = adapter.fetch(key, options) do
          zero_counts
        end

        loss = loss(Time.now.to_i, resource[:timestamp], average(options),
                    window(options))
        count = resource[:count] - loss
        count > 0 ? count : 0
      end

      # Validates the options given. Window, average and maximum values must be set 
      # either through default values or the options
      #
      # Options are same as +increment+
      def validate?(options)
        super(options)
        window, average, maximum = window(options), average(options), maximum(options)

        if !window || !average || !maximum
          raise ArgumentError.new("window, average and maximum options are required")
        elsif !positive_integer?(window)
          raise ArgumentError.new("time window must be a positive integer")
        elsif !non_negative_numeric?(average)
          raise ArgumentError.new("average should be non negative numbers")
        elsif maximum < average
          raise ArgumentError.new("maximum should not be less than the average")
        end

        true
      end

      # Reset the count of the resource identified by the key to 0.
      #
      # ====== Attributes
      #
      # * +key+ - the identifier for the resource in cache store
      def reset(key, options)
        adapter.write(key, zero_counts)
      end

      def identifier #:nodoc:
        :leaky_bucket
      end

      # calculates the loss given an average, window and a time interval
      def loss(now, last_accessed, average, window)
        loss = ((now - last_accessed) * average).to_f/window
        loss > 0 ? loss : 0
      end

      private
      def zero_counts #:nodoc:
        {count: 0, timestamp: Time.now.to_i}
      end

      def window(options) #:nodoc:
        options[:window] || self.class.default_window
      end

      def average(options) #:nodoc:
        options[:average] || self.class.default_average
      end

      def maximum(options) #:nodoc:
        options[:maximum] || options[:limit] || self.class.default_maximum
      end

      def positive_integer?(e) #:nodoc:
        e.is_a?(Integer) && e > 0
      end

      def non_negative_numeric?(e) #:nodoc:
        e.is_a?(Numeric) && e >= 0
      end
    end
  end
end
