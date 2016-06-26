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
    i_suck_and_my_tests_are_order_dependent!

    before do
      FineTune::Strategies::Base.stubs(:registry).returns(
          {:sample => FineTune::Strategies::SampleStrategy})
    end

    it "should not need defaults to be setup" do
      throttled = FineTune.throttle(:email_rate_xyz, 'testxyz@example.com',
                              {limit: 10, window: 3600, strategy: :sample})
      assert throttled
    end

    it "accepts limit threshold" do
      flunk
    end

    it "accepts window option" do
      flunk
    end

    it "accepts strategy option" do
      flunk
    end

    it "can pass a block" do
      flunk
    end
  end

  describe "throttle!" do
  end

  describe "strategy" do
  end

  describe "adaptor" do
  end
end
