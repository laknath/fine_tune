module FineTune
  module Strategies
    class LeakyBucket < Base

      class << self
        attr_accessor :default_window, :default_average, :default_maximum
      end

      def compare?(count, options)
        count <=> maximum(options)
      end

      def increment(key, options)
        count = count(key, options)
        count = [maximum(options), count + 1].min
        adapter.write(key, {count: count, timestamp: Time.now.to_i})
        count
      end

      def count(key, options)
        resource = adapter.fetch(key, options) do
          zero_counts
        end

        loss = loss(Time.now.to_i, resource[:timestamp], average(options),
                    window(options))
        count = resource[:count] - loss
        count > 0 ? count : 0
      end

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

      def reset(key, options)
        adapter.write(key, zero_counts)
      end

      def identifier
        :leaky_bucket
      end

      def loss(now, last_accessed, average, window)
        loss = ((now - last_accessed) * average).to_f/window
        loss > 0 ? loss : 0
      end

      private
      def zero_counts
        {count: 0, timestamp: Time.now.to_i}
      end

      def window(options)
        options[:window] || self.class.default_window
      end

      def average(options)
        options[:average] || self.class.default_average
      end

      def maximum(options)
        options[:maximum] || options[:limit] || self.class.default_maximum
      end

      def positive_integer?(e)
        e.is_a?(Integer) && e > 0
      end

      def non_negative_numeric?(e)
        e.is_a?(Numeric) && e >= 0
      end
    end
  end
end
