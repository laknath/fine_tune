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

  describe "throttling events" do
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
  end

  describe "throttle!" do
    before do
      FineTune::Base.stubs(:registry).
                returns({:sample => FineTune::Strategies::SampleStrategy})
    end
  end

  describe "strategy" do
    it "should return default strategy if strategy is invalid" do
      flunk
    end

    it "should return default strategy if strategy is nil" do
      flunk
    end

    it "accepts strategy option" do
      flunk
    end

    it "raises resource key undefined if invalidated" do
      flunk
    end
  end

  describe "adaptor" do
  end
end
