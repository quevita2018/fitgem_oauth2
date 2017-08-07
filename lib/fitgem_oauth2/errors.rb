module FitgemOauth2
  class InvalidDateArgument < ArgumentError
  end

  class InvalidTimeArgument < ArgumentError

  end

  class InvalidArgumentError < ArgumentError
  end

  # HTTP errors
  class BadRequestError < StandardError
  end

  class UnauthorizedError < StandardError
  end

  class ForbiddenError < StandardError
  end

  class NotFoundError < StandardError
  end

  class NotAllowedError < StandardError
  end

  class ConflictError < StandardError
  end

  class ServerError < StandardError
  end

  class RateLimitError < StandardError
  end
end
