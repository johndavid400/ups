require 'httparty'
require 'json'
require 'base64'

require_relative 'ups_shipping/version'
require_relative 'ups_shipping/configuration'
require_relative 'ups_shipping/client'
require_relative 'ups_shipping/rating'
require_relative 'ups_shipping/shipping'
require_relative 'ups_shipping/models/address'
require_relative 'ups_shipping/models/package'
require_relative 'ups_shipping/models/rate_request'
require_relative 'ups_shipping/models/ship_request'
require_relative 'ups_shipping/errors'

module UpsShipping
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def client
      @client ||= Client.new(configuration)
    end
  end
end
