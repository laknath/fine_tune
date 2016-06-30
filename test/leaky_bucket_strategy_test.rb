require 'test_helper'

describe FineTune::Strategies::LeakyBucket do
  before do
    FineTune.adapter = ActiveSupport::Cache::MemoryStore.new 
    @time = Time.now
    set_time(@time)
    @leaky_bucket = FineTune::Strategies::LeakyBucket.instance
  end

  describe "increment" do
    it "returns the initial count + 1 in first time" do
      saved = {count: 1, timestamp: @time.to_i}
      assert_equal 1, @leaky_bucket.increment(:my_email_rate,
                          {average: 10, window: 500, maximum: 20})
      assert_equal saved, FineTune.adapter.read(:my_email_rate)
    end

    it "returns the incremented count after first time" do
      FineTune.adapter.write(:my_email_rate, {count: 7, timestamp: @time.to_i - 250})
      assert_equal 3, @leaky_bucket.increment(:my_email_rate,
                          {average: 10, window: 500, maximum: 20})

      saved = {count: 3, timestamp: @time.to_i}
      assert_equal saved, FineTune.adapter.read(:my_email_rate)
    end

    it "guarantees maximum is the burst threshold" do
      FineTune.adapter.write(:my_email_rate, {count: 20, timestamp: @time.to_i})
      assert_equal 20, @leaky_bucket.increment(:my_email_rate,
                          {average: 10, window: 500, maximum: 20})

      saved = {count: 20, timestamp: @time.to_i}
      assert_equal saved, FineTune.adapter.read(:my_email_rate)
    end
  end

  describe "count" do
    it "returns zero counts for the first time" do
      count = @leaky_bucket.count(:something, {average: 10, window: 3600})
      assert_equal 0, count
    end

    it "calls the loss with custom average and maximum" do
      FineTune.adapter.write(:something, {count: 10, timestamp: @time.to_i - 100})

      @leaky_bucket.expects(:loss).with(@time.to_i, @time.to_i - 100, 20, 60).returns(0)
      @leaky_bucket.count(:something, {average: 20, window: 60})
    end

    it "returns the current count after the loss" do
      FineTune.adapter.write(:something, {count: 20, timestamp: @time.to_i - 200})
      assert_equal 15, @leaky_bucket.count(:something, {average: 10, window: 400})
    end

    it "guarantees minimum is 0" do
      FineTune.adapter.write(:something, {count: 2, timestamp: @time.to_i - 200})
      assert_equal 0, @leaky_bucket.count(:something, {average: 10, window: 400})
    end
  end

  describe "loss" do
    it "returns 0 if loss is negative" do
      assert_equal 0, @leaky_bucket.loss(10000, 10001, 5, 10)
    end

    it "returns loss if positive" do
      assert_equal 0.5, @leaky_bucket.loss(10001, 10000, 5, 10)
    end

    it "returns 0 if no loss" do
      assert_equal 0, @leaky_bucket.loss(10000, 10000, 5, 10)
    end
  end

  describe "reset" do
    it "sets the count to 0" do
      FineTune.adapter.write(:something, {count: 10, timestamp: @time.to_i - 100})
      @leaky_bucket.reset(:something, {})
      exp = {count: 0, timestamp: @time.to_i}
      assert_equal(exp, FineTune.adapter.read(:something))
    end
  end

  describe "validate?" do
    it "raises an error if no window given" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({limit: 9, average: 10})
      end
      assert_equal error.message, 'window, average and maximum options are required'
    end

    it "raises an error if no limit given" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({window: 9, average: 10})
      end
      assert_equal error.message, 'window, average and maximum options are required'
    end

    it "raises an error if no average given" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({window: 9, maximum: 10})
      end
      assert_equal error.message, 'window, average and maximum options are required'
    end

    it "raises an error if window is not a positive integer" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({window: 0, maximum: 10, average: 10})
      end
      assert_equal error.message, 'time window must be a positive integer'
    end

    it "raises an error if average is negative" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({window: 1, maximum: 1, average: -1})
      end
      assert_equal error.message, 'average should be non negative numbers'
    end

    it "raises an error if maximum is less than average" do
      error = assert_raises ArgumentError do 
        @leaky_bucket.validate?({window: 1, maximum: 1, average: 2})
      end
      assert_equal error.message, 'maximum should not be less than the average'
    end
  end

  describe "build_key" do
    it "concatenates name, strategy and id" do
      assert_equal "fine_tune/something/leaky_bucket/a1z",
        @leaky_bucket.build_key(:something, 'a1z', nil)
    end

    it "can pass array as an id" do
      assert_equal "fine_tune/something/leaky_bucket/admin/a1z",
        @leaky_bucket.build_key(:something, [:admin, 'a1z'], {})
    end
  end

  describe "compare?" do
    it "returns 0 if equal, threshold as :maximum" do
      assert_equal 0, @leaky_bucket.compare?(10, {maximum: 10})
    end

    it "returns 0 if equal, threshold as :limit" do
      assert_equal 0, @leaky_bucket.compare?(10, {limit: 10})
    end

    it "returns -1 if less" do
      assert_equal -1, @leaky_bucket.compare?(9, {maximum: 10})
    end

    it "returns 1 if greater" do
      assert_equal 1, @leaky_bucket.compare?(11, {maximum: 10})
    end
  end
end
