require 'test_helper'

describe FineTune::Base do
  before do
  end

  it "returns a version number" do
    refute_nil ::FineTune::VERSION
  end

  describe "setting up default limits" do
    it "returns a singleton" do
      assert FineTune::Base.instance.equal?(FineTune::Base.instance)
    end

    it "accepts default options" do
      FineTune::Base.set_limit(:hourly_emails, window: 1, threshold: 10)
    end

    it "can override limits" do
    end

    it "can unset defined rules" do
    end
  end

  describe "restricting events for a resource" do
    it "accepts limit threshold" do
    end

    it "accepts window option" do
    end

    it "accepts strategy option" do
    end

    it "accepts limit threshold" do
    end

    it "accepts window option" do
    end

    it "accepts strategy option" do
    end
  end
end
