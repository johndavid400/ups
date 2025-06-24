module Ups
  class Configuration
    attr_accessor :client_id, :client_secret, :account_number, :negotiated_rates, :sandbox

    def initialize(params = {})
      @sandbox = true
      @negotiated_rates = false
      params.map{|k, v| send("#{k}=", v) if respond_to?("#{k}=") }
    end

    def base_url
      @sandbox ? "https://wwwcie.ups.com" : "https://onlinetools.ups.com"
    end

    def oauth_url
      @sandbox ? "https://wwwcie.ups.com/security/v1/oauth/token" : "https://onlinetools.ups.com/security/v1/oauth/token"
    end
  end
end
