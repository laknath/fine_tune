module FineTune
  module Strategies
    class SampleStrategy < Base
      def increment(key, options)
        10
      end

      def validate?(options)
        true
      end
    end
  end
end
