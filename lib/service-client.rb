require "service-client/version"
require "service-client/error"
require "service-client/routing_error"
require "service-client/raw_interface"
require "service-client/adapter/faraday"
require "service-client/url_pattern"
require "service-client/bound_route"
require "service-client/route"
require "service-client/route_collection"

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

     raw.request(method, url, body, {})
    end
  end
end
