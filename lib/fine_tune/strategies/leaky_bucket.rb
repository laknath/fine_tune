module FineTune
  module Strategies
    class LeakyBucket < Base

      class << self
        attr_accessor :default_window, :default_average, :default_maximum
      end

      @default_interval = 3600 #one hour
      @default_maximum  = 30
      @default_average  = 25

      def compare?(count, options)
        count <=> average(options)
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

        loss = loss(Time.now.to_i, resource.timestamp, average(options),
                    window(options))
        count = resource.count - loss
        count > 0 ? count : 0
      end

      def validate?(options)
        true
      end

      def reset(key, options)
        adapter.write(key, zero_counts)
      end

      def identifier
        :leaky_bucket
      end

      private
      def adapter(adapter)
        adapter || FineTune.adapter
      end

      def loss(now, last_accessed, average, window)
        loss = ((now - last_accessed) * average).to_f/window
        loss > 0 ? loss : 0
      end

      def zero_counts
        {count: 0, timestamp: Time.now.to_i}
      end

      def window(options)
        options[:window] || self.class.default_window
      end

      def average(options)
        options[:average] || options[:limit] || self.class.default_average
      end

      def maximum(options)
        options[:maximum] || self.class.default_maximum
      end
    end
  end
end
