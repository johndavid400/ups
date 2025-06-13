require 'httparty'
require 'json'
require 'base64'

require_relative 'ups/version'
require_relative 'ups/configuration'
require_relative 'ups/client'
require_relative 'ups/rating'
require_relative 'ups/shipping'
require_relative 'ups/models/address'
require_relative 'ups/models/package'
require_relative 'ups/models/rate_request'
require_relative 'ups/models/ship_request'
require_relative 'ups/errors'

module Ups
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
