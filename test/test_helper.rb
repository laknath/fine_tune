$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
require "minitest/reporters"
require 'minitest/autorun'
require "mocha/setup"

require 'fine_tune'
require 'sample_strategy'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
