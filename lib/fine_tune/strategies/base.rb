module FineTune
  module Strategies
    class Base
      include Singleton

      @@registry = {
        :leaky_bucket => ::FineTune::Strategies::LeakyBucket,
        :sliding_window => ::FineTune::Strategies::SlidingWindow
      }

      def compare?(count, options)
        count <=> options[:limit]
      end

      def build_key(name, id, options)
        [name, id].flatten.join('-')
      end

      def increment(key, options)
        raise "not defined"
      end

      def count(key, options)
        raise "not defined"
      end

      def validate?(options)
        false
      end

      def reset(key, options)
        raise "not defined"
      end

      def self.registry
        @@registry
      end
    end
  end
end
