require "fine_tune/version"
require "fine_tune/strategies/base"
Dir[File.dirname(__FILE__) + "/fine_tune/strategies/*.rb"].each do |filename|
  require filename
end
require "fine_tune/base"
require "fine_tune/max_rate_error"

module FineTune
  class << self
    extend Forwardable
    def_delegators :"FineTune::Base.instance", :adapter, :adapter=, :count,
                    :reset, :throttle, :throttle!, :add_limit, :remove_limit, :rate_exceeded?
  end
end

