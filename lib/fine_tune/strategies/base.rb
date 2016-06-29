module FineTune
  module Strategies
    class Base
      include Singleton

      def compare?(count, options)
        count <=> options[:limit]
      end

      def build_key(name, id, options)
        [name, identifier, id].flatten.join('-')
      end

      def identifier
        raise "not defined"
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
    end
  end
end
