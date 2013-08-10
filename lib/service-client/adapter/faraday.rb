require 'faraday'
require 'uri'
require 'rack'

module Service
  class Client::Adapter
    class Faraday
      def initialize(options = {})
        @adapter = options.delete :adapter
        @builder = options.delete :builder
      end

      def request(method, url, body, options)
        uri = URI.parse(url)

        connection = create_connection(uri)

        response = send_request(connection, method, uri, body, options)

        Rack::Response.new(response.body || '', response.status, response.headers)
      end

      protected
      def send_request(connection, method, uri, body, options)
        connection.send(method) do |request|
          request.url path(uri)
          request.body = body
          if method == :get && uri.query
            request.params = ::Faraday::Utils.parse_nested_query(uri.query)
          end
          request.headers = options[:headers] || {}
        end
      end

      def path(uri)
        "#{uri.path}"
      end

      def base_url(uri)
        "#{uri.scheme}://#{auth(uri)}#{uri.host}:#{uri.port}"
      end

      def auth(uri)
        (uri.user && uri.password) ? "#{uri.user}:#{uri.password}@" : ''
      end

      def create_connection(uri)
        ::Faraday.new(:url => base_url(uri)) do |faraday|
          # if this returns false it skips the adapter selection later
          builder_response = @builder ? @builder.call(faraday) : true

          if @adapter && builder_response
            faraday.adapter *@adapter
          else
            faraday.adapter ::Faraday.default_adapter
          end
        end
      end
    end
  end
end
