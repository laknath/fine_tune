module FineTune
  module Strategies
    class Base
      @@registry = {
        :leaky_bucket => FineTune::Strategies.LeakyBucket,
        :sliding_window => FineTune::Strategies.SlidingWindow
      }
    end

    def compare(resource_id, limits)
    end

    def increment(resource_id)
    end

    def count(resource_id)
    end

    def self.registry
      @@registry
    end
  end
end
