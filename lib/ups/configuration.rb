module Ups
  class Configuration
    attr_accessor :client_id, :client_secret, :account_number, :sandbox

    def initialize
      @sandbox = true
    end

    def base_url
      @sandbox ? "https://wwwcie.ups.com" : "https://onlinetools.ups.com"
    end

    def oauth_url
      @sandbox ? "https://wwwcie.ups.com/security/v1/oauth/token" : "https://onlinetools.ups.com/security/v1/oauth/token"
    end
  end
end
