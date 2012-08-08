# -*- encoding: utf-8 -*-
require File.expand_path('../lib/service-client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Thorben Schröder"]
  gem.email         = ["stillepost@gmail.com"]
  gem.description   = %q{Service::Client is a generic client gem to access our services. It is the base for explicit clients for each service so that those explicit clients are easy and fast to implement and maintain.}
  gem.summary       = %q{Service::Client is a generic client gem to access our services.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "service-client"
  gem.require_paths = ["lib"]
  gem.version       = Service::Client::VERSION

  gem.add_dependency 'faraday', '0.8.1'
end
