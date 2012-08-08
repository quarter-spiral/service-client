require 'faraday'
require 'uri'
require 'rack'

module Service
  class Client::Adapter
    class Faraday
      def request(method, url, body, options)
        uri = URI.parse(url)

        auth = (uri.user && uri.password) ? "#{uri.user}:#{uri.password}@" : ''
        base_url = "#{uri.scheme}://#{auth}#{uri.host}:#{uri.port}"
        path = "#{uri.path}?#{uri.query}"

        connection = ::Faraday.new(:url => base_url)
        response = connection.send(method) do |request|
          request.url path
          request.body = body
          request.headers = options[:headers] || {}
        end
        Rack::Response.new(response.body, response.status, response.headers)
      end
    end
  end
end
