module FineTune
  module Strategies
    # This class is only for the purpose of extending and implementing
    # own strategies. Any subclass should implement:
    # * +identifier+
    # * +increment+
    # * +count+
    # * +reset+
    class Base
      include Singleton

      def compare?(count, options)
        count <=> options[:limit]
      end

      def build_key(name, id, options)
        [:fine_tune, name, identifier, id].flatten.join('/')
      end

      def adapter
        FineTune.adapter
      end

      def identifier
        raise "not defined"
      end

      def increment(key, options)
        count(key, options) +
          (options && options[:step] || 1)
      end

      def count(key, options)
        raise "not defined"
      end

      def validate?(options)
        if adapter.nil?
          raise "no adapter given"
        end

        true
      end

      def reset(key, options)
        raise "not defined"
      end
    end
  end
end
