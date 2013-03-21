require "service-client/version"
require "service-client/error"
require "service-client/routing_error"
require "service-client/service_error"
require "service-client/response_error"
require "service-client/raw_interface"
require "service-client/adapter/faraday"
require "service-client/url_pattern"
require "service-client/bound_route"
require "service-client/route"
require "service-client/route_collection"
require "service-client/base_response"
require "service-client/response"
require "service-client/redirection"

require 'json'
require 'cgi'

module Service
  class Client
    attr_reader :base_url

    def initialize(base_url)
      @base_url = base_url
    end

    def raw
      @raw_interface ||= RawInterface.new(self)
    end

    def routes
      @routes ||= RouteCollection.new
    end
    alias urls routes

    def get(bound_route, token, body_hash = nil)
      request(:get, token, bound_route, body_hash)
    end

    def put(bound_route, token, body_hash = nil)
      request(:put, token, bound_route, body_hash)
    end

    def post(bound_route, token, body_hash = nil)
      request(:post, token, bound_route, body_hash)
    end

    def delete(bound_route, token, body_hash = nil)
      request(:delete, token, bound_route, body_hash)
    end

    protected
    def request(method, token, bound_route, body_hash)
      url = bound_route.url_for_method(method)

      body = nil
      if method == :get
        url = append_body_hash_to_url(url, body_hash)
      else
        body = body_hash ? JSON.dump(body_hash) : ''
      end

      raw_response = raw.request(method, url, body, headers: {'AUTHORIZATION' => "Bearer #{token}"})
      case raw_response.status
      when 200, 201, 304
       Response.new(raw_response)
      when 301, 302, 303, 307
        raise Redirection.new(raw_response)
      else
        error = nil
        begin
          error = JSON.parse(raw_response.body.first)['error']
        rescue JSON::ParserError
          # treat invalid JSON the same as non-present error field
        end
        if error
          raise ServiceError.new(error)
        else
          raise ResponseError.new(raw_response)
        end
      end
    end

    def append_body_hash_to_url(url, body_hash)
      return url if !body_hash || body_hash.empty?

      uri = URI.parse(url)

      if body_hash && !body_hash.empty?
        uri.query += '&' if uri.query
        uri.query ||= ''
        uri.query += Faraday::Utils.build_nested_query(body_hash)
      end

      uri.to_s
    end
  end
end
