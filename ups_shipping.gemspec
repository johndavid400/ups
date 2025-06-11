# ups_shipping.gemspec
Gem::Specification.new do |spec|
  spec.name          = "ups_shipping"
  spec.version       = "0.0.1"
  spec.authors       = ["JD Warren"]
  spec.email         = ["johndavid400@gmail.com"]
  spec.summary       = "Ruby wrapper for UPS Shipping API"
  spec.description   = "A Ruby gem that provides easy access to UPS shipping rates and label creation"
  spec.homepage      = "https://github.com/johndavid400/ups_shipping"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "json", "~> 2.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
end
