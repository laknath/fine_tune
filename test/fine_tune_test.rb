require 'test_helper'

describe FineTune::Base do
  it "returns a version number" do
    refute_nil ::FineTune::VERSION
  end

  describe "setting up default limits" do
    before do
      FineTune.add_limit(:hourly_emails, window: 1, threshold: 10)
    end

    it "returns a singleton" do
      assert FineTune::Base.instance.equal?(FineTune::Base.instance())
    end

    it "accepts default options" do
      assert_equal FineTune::Base.instance.limits[:hourly_emails],
                            {window: 1, threshold: 10}
    end

    it "can override limits" do
      FineTune.add_limit(:hourly_emails, window: 2, threshold: 11)
      assert_equal FineTune::Base.instance.limits[:hourly_emails],
                            {window: 2, threshold: 11}
    end

    it "can unset defined rules" do
      FineTune.remove_limit(:hourly_emails)
      assert_nil FineTune::Base.instance.limits[:hourly_emails]
    end
  end

  describe "throttle" do
    before do
      FineTune::Base.stubs(:registry).
                returns({:sample => FineTune::Strategies::SampleStrategy})
    end

    it "should not need defaults to be setup" do
      FineTune::Base.instance.stubs(:limits).returns({})
      assert FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 10, window: 3600, strategy: :sample})
    end

    it "should override defaults" do
      FineTune.add_limit(:email_rate, {limit: 20, window: 1800})
      FineTune::Strategies::SampleStrategy.instance.expects(:compare?).
                with(10, {limit: 5, window: 1800, strategy: :sample}).returns(1).once
      FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 5, strategy: :sample})
    end

    it "can pass a block" do
      block_called = false
      FineTune.throttle(:email_rate, 'frodo@example.com',
              {limit: 5, strategy: :sample}) { block_called = true }
      assert block_called
    end

    it "returns true when compared greater than the limit" do
      assert FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 9, window: 3600, strategy: :sample})
    end

    it "returns false when compared less than the limit" do
      refute FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 11, window: 3600, strategy: :sample})
    end

    it "returns true when compared equal to the limit" do
      assert FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 10, window: 3600, strategy: :sample})
    end
  end

  describe "throttle!" do
    before do
      FineTune::Base.stubs(:registry).
                returns({:sample => FineTune::Strategies::SampleStrategy})
    end

    it "should not need defaults to be setup" do
      FineTune::Base.instance.stubs(:limits).returns({})

      assert_raises FineTune::MaxRateError do 
        FineTune.throttle!(:email_rate, 'frodo@example.com',
                              {limit: 10, window: 3600, strategy: :sample})
      end
    end

    it "should override defaults" do
      FineTune.add_limit(:email_rate, {limit: 20, window: 1800})
      FineTune::Strategies::SampleStrategy.instance.expects(:compare?).
                with(10, {limit: 5, window: 1800, strategy: :sample}).returns(1).once

      assert_raises FineTune::MaxRateError do 
        FineTune.throttle!(:email_rate, 'frodo@example.com',
                              {limit: 5, strategy: :sample})
      end
    end

    it "can pass a block" do
      block_called = false
      assert_raises FineTune::MaxRateError do 
        FineTune.throttle!(:email_rate, 'frodo@example.com',
              {limit: 5, strategy: :sample}) { block_called = true }
      end
      assert block_called
    end

    it "raises an max rate error when compared greater than the limit" do
      assert_raises FineTune::MaxRateError do 
        FineTune.throttle!(:email_rate, 'frodo@example.com',
                              {limit: 9, window: 3600, strategy: :sample})
      end
    end

    it "returns false when compared less than the limit" do
      refute FineTune.throttle!(:email_rate, 'frodo@example.com',
                              {limit: 11, window: 3600, strategy: :sample})
    end

    it "returns true when compared equal to the limit" do
      assert_raises FineTune::MaxRateError do 
        FineTune.throttle!(:email_rate, 'frodo@example.com',
                             {limit: 10, window: 3600, strategy: :sample})
      end
    end
  end

  describe "strategy" do
    before do
      FineTune::Base.stubs(:registry).
                returns({:sample => FineTune::Strategies::SampleStrategy})
    end

    it "should return default strategy if strategy is invalid" do
      assert_equal FineTune::Base.default_strategy.instance,
                            FineTune::Base.find_strategy(:something)
    end

    it "should return default strategy if strategy is nil" do
      assert_equal FineTune::Base.default_strategy.instance,
                            FineTune::Base.find_strategy(nil)
    end

    it "accepts strategy option" do
      FineTune::Base.expects(:find_strategy).
                with(:sample).
                returns(FineTune::Strategies::SampleStrategy.instance).once
      FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 9, window: 3600, strategy: :sample})
    end

    it "raises resource key undefined if invalidated" do
      FineTune::Strategies::SampleStrategy.
                  instance.stubs(:validate?).returns(false)

      error = assert_raises RuntimeError do 
        FineTune.throttle(:email_rate, 'frodo@example.com',
                              {limit: 9, window: 3600, strategy: :sample})
      end
      assert_equal 'resource key undefined', error.message
    end
  end
end
