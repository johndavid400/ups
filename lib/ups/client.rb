module Ups
  class Client
    include HTTParty

    attr_reader :config, :access_token

    def initialize(config)
      @config = config
      @access_token = nil
      authenticate
    end

    def get(endpoint, options = {})
      request(:get, endpoint, options)
    end

    def post(endpoint, options = {})
      request(:post, endpoint, options)
    end

    private

    def auth_headers
      {
        'Authorization' => "Basic #{auth_string}",
        'X-Merchant-Id' => @config.client_id,
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end

    def auth_string
      @auth_string ||= Base64.strict_encode64("#{@config.client_id}:#{@config.client_secret}")
    end

    def authenticate
      response = HTTParty.post(@config.oauth_url, { headers: auth_headers, body: 'grant_type=client_credentials' })

      if response.success?
        @access_token = response.parsed_response['access_token']
      else
        raise AuthenticationError, "Failed to authenticate: #{response.body}"
      end
    end

    def request_headers
      {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      }
    end

    def request(method, endpoint, opts = {})
      url = "#{@config.base_url}#{endpoint}"
      response = HTTParty.send(method, url, { headers: request_headers.merge(opts[:headers] || {}), body: opts[:body]&.to_json })
      handle_response(response)
    end

    def handle_response(response)
      case response.code
      when 200, 201
        response.parsed_response
      when 401
        authenticate
        raise AuthenticationError, "Authentication failed"
      when 400
        raise BadRequestError, response.body
      when 404
        raise NotFoundError, response.body
      when 500
        raise ServerError, response.body
      else
        raise APIError, "HTTP #{response.code}: #{response.body}"
      end
    end
  end
end
