require "service-client/version"
require "service-client/error"
require "service-client/routing_error"
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

    def get(bound_route, body_hash = nil)
      request(:get, bound_route, body_hash)
    end

    def put(bound_route, body_hash = nil)
      request(:put, bound_route, body_hash)
    end

    def post(bound_route, body_hash = nil)
      request(:post, bound_route, body_hash)
    end

    def delete(bound_route, body_hash = nil)
      request(:delete, bound_route, body_hash)
    end

    protected
    def request(method, bound_route, body_hash)
     url = bound_route.url_for_method(method)
     body = body_hash ? JSON.dump(body_hash) : ''

     raw_response = raw.request(method, url, body, {})
     case raw_response.status
     when 200
      Response.new(raw_response)
     when 301, 302, 303, 307
       raise Redirection.new(raw_response)
     end
    end
  end
end
