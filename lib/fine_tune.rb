#
# Author:: Laknath Semage (blaknath at gmail dot com)
# Copyright:: Copyright (c) 2016 Vesess Inc.
# License:: MIT License

require "fine_tune/version"
require 'singleton'
require "forwardable"
require "fine_tune/strategies/base"
Dir[File.dirname(__FILE__) + "/fine_tune/strategies/*.rb"].each do |filename|
  require filename
end
require "fine_tune/base"
require "fine_tune/max_rate_error"

##
# FineTune helps throttle any kind of event sequence. It also supports 
# custom throttling strategies using a common API. By default
# it supports LeakyBucket[https://en.wikipedia.org/wiki/Leaky_bucket] algorithm.

module FineTune
  class << self
    extend Forwardable
    def_delegators :"FineTune::Base.instance", :count, :reset, :throttle, 
                    :throttle!, :add_limit, :remove_limit, :rate_exceeded?
    def_delegators :"FineTune::Base", :adapter, :adapter=, :default_strategy,
                    :default_strategy=
  end
end

