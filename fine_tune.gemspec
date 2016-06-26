# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fine_tune/version'

Gem::Specification.new do |spec|
  spec.name          = "fine_tune"
  spec.version       = FineTune::VERSION
  spec.authors       = ["Laknath Semage"]
  spec.email         = ["blaknath@gmail.com"]

  spec.summary       = %q{Limits rate of a given event sequence with defined strategies.}
  spec.description   = %q{A rate limiter without the worst case throttling of two times the defined threshold.}
  spec.homepage      = "https://github.com/vesess/fine_tune"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.1.9"
  spec.add_development_dependency "mocha", "~> 0.14.0"
end
