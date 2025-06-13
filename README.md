# UPS Shipping Ruby Gem

A Ruby wrapper for the UPS Shipping API that allows you to get shipping rates and create shipping labels.

This gem handles the new OAuth flow in the UPS API that retrieves a JWT first to make requests with. It will allow you to fetch rates for a given package and purchase a shipping label.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ups'
```

## Configuration

```ruby
# config/initializers/ups.rb

Ups.configure do |config|
  config.client_id = Rails.application.credentials.ups.client_id
  config.client_secret = Rails.application.credentials.ups.client_secret
  config.account_number = Rails.application.credentials.ups.account
  config.sandbox = false
end
```

## Usage

### Getting Shipping Rates

```ruby
# Create addresses
shipper = Ups::Address.new(
  company_name: "ACME Corp",
  address_line_1: "123 Main St",
  city: "Atlanta",
  state: "GA",
  postal_code: "30309",
  country_code: "US",
  phone: "1234567890"
)

ship_to = Ups::Address.new(
  name: "John Doe",
  address_line_1: "456 Oak Ave",
  city: "New York",
  state: "NY",
  postal_code: "10001",
  country_code: "US"
)

# Create package
package = Ups::Package.new(
  length: 10,
  width: 8,
  height: 6,
  weight: 5
)

# Create rate request
rate_request = Ups::RateRequest.new(
  shipper: shipper,
  ship_to: ship_to,
  ship_from: shipper,
  service_code: "03" # UPS Ground
)
rate_request.add_package(package)

# Get rates
rating_service = Ups::Rating.new(Ups.client)
rates = rating_service.get_rates(rate_request)

rates.each do |rate|
  puts "#{rate[:service_name]}: $#{rate[:total]} #{rate[:currency]}"
end
```

### Creating Shipping Labels

```ruby
# Create ship request (using same addresses and packages from above)
ship_request = Ups::ShipRequest.new(
  shipper: shipper,
  ship_to: ship_to,
  ship_from: shipper,
  service_code: "03",
  description: "Test shipment"
)
ship_request.add_package(package)

# Create shipment
shipping_service = Ups::Shipping.new(Ups.client)
result = shipping_service.create_shipment(ship_request)

puts "Tracking Number: #{result[:tracking_number]}"
puts "Total Cost: $#{result[:total]} #{result[:currency]}"
puts "Label: #{result[:label]}"
```

## Service Codes

- 01: UPS Next Day Air
- 02: UPS 2nd Day Air
- 03: UPS Ground
- 07: UPS Worldwide Express
- 08: UPS Worldwide Expedited
- 11: UPS Standard
- 12: UPS 3 Day Select
- 13: UPS Next Day Air Saver
- 14: UPS Next Day Air Early AM
