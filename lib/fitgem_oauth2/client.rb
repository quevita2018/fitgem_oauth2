require 'fitgem_oauth2/activity.rb'
require 'fitgem_oauth2/body_measurements.rb'
require 'fitgem_oauth2/devices.rb'
require 'fitgem_oauth2/errors.rb'
require 'fitgem_oauth2/food.rb'
require 'fitgem_oauth2/friends.rb'
require 'fitgem_oauth2/heartrate.rb'
require 'fitgem_oauth2/sleep.rb'
require 'fitgem_oauth2/subscriptions.rb'
require 'fitgem_oauth2/users.rb'
require 'fitgem_oauth2/utils.rb'
require 'fitgem_oauth2/version.rb'

require 'base64'
require 'faraday'

module FitgemOauth2
  class Client

    DEFAULT_USER_ID = '-'
    API_VERSION = '1'
    ONE_MONTH = 30 * 24 * 60 * 60

    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :token
    attr_reader :user_id

    def initialize(opts)
      missing = [:client_id, :client_secret, :token] - opts.keys
      if missing.size > 0
        raise FitgemOauth2::InvalidArgumentError, "Missing required options: #{missing.join(',')}"
      end

      @client_id = opts[:client_id]
      @client_secret = opts[:client_secret]
      @token = opts[:token]
      @user_id = (opts[:user_id] || DEFAULT_USER_ID)

      @connection = Faraday.new('https://api.fitbit.com')
    end

    def refresh_access_token(refresh_token, opts = {})
      response = connection.post('/oauth2/token') do |request|
        encoded = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        request.headers['Authorization'] = "Basic #{encoded}"
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        request.params['grant_type'] = 'refresh_token'
        request.params['refresh_token'] = refresh_token
        request.params['expires_in'] = opts[:expires_in] || ONE_MONTH
      end
      JSON.parse(response.body)
    end

    def revoke_access_token(token)
      response = connection.post('/oauth2/revoke') do |request|
        encoded = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        request.headers['Authorization'] = "Basic #{encoded}"
        request.params['token'] = token
      end
      JSON.parse(response.body)
    end

    def get_call(url)
      url = "#{API_VERSION}/#{url}"
      response = connection.get(url) { |request| set_headers(request) }
      parse_response(response)
    end

    def post_call(url, params = {})
      url = "#{API_VERSION}/#{url}"
      response = connection.post(url, params) { |request| set_headers(request) }
      parse_response(response)
    end

    def delete_call(url)
      url = "#{API_VERSION}/#{url}"
      response = connection.delete(url) { |request| set_headers(request) }
      parse_response(response)
    end

    private
    attr_reader :connection

    def set_headers(request)
      request.headers['Authorization'] = "Bearer #{token}"
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    end

    def parse_response(response)
      headers_to_keep = %w(fitbit-rate-limit-limit fitbit-rate-limit-remaining fitbit-rate-limit-reset)

      error_handler = {
          200..201 => lambda {
            if response['content-type'] == 'application/vnd.garmin.tcx+xml;charset=UTF-8'
              response.body
            else
              body = JSON.parse(response.body)
              body = {body: body} if body.is_a?(Array)
              body.merge!(response.headers.slice(*headers_to_keep))
            end
          },
          204 => lambda { response.headers.slice(*headers_to_keep) },
          400 => lambda { raise FitgemOauth2::BadRequestError.new(JSON.parse(response.body)) },
          401 => lambda { raise FitgemOauth2::UnauthorizedError.new(JSON.parse(response.body)) },
          403 => lambda { raise FitgemOauth2::ForbiddenError.new(JSON.parse(response.body)) },
          404 => lambda { raise FitgemOauth2::NotFoundError.new(response.body) },
          405 => lambda { raise FitgemOauth2::NotAllowedError },
          409 => lambda { raise FitgemOauth2::ConflictError },
          429 => lambda { raise FitgemOauth2::RateLimitError },
          500..599 => lambda { raise FitgemOauth2::ServerError }
      }

      fn = error_handler.detect { |k, _| k === response.status }
      if fn === nil
        raise StandardError, "Unexpected response status #{response.status}"
      else
        fn.last.call
      end
    end
  end
end
