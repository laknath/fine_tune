module FineTune #:nodoc: all
  module Strategies
    class SampleStrategy < Base
      def increment(key, options)
        10
      end

      def count(key, options)
        9
      end

      def validate?(options)
        true
      end

      def identifier
        :sample
      end
    end
  end
end
