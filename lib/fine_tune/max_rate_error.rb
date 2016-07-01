module FineTune
  # MaxRateError is thrown when a defined limit has reached
  class MaxRateError < StandardError
    attr_accessor :key, :comparison, :count, :strategy, :options  

    def initialize(key, count, comp, strategy, options)
      @key = key
      @count = count
      @comparison = comp
      @strategy = strategy
      @options = options

      super("Rate limited with strategy #{strategy} for key #{key}")
    end
  end
end
