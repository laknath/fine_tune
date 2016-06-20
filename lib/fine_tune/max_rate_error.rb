module FineTune
  class MaxRateError < StandardError
    attr_accessor :key, :count, :strategy, :options  

    def initialize(key, count, strategy, options)
      @key = key
      @count = count
      @strategy = strategy
      @options = options

      super("Rate limited with strategy #{strategy} for key #{key}")
    end
  end
end
