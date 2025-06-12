module UpsShipping
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class ValidationError < Error; end
  class BadRequestError < Error; end
  class NotFoundError < Error; end
  class ServerError < Error; end
  class APIError < Error; end
end

