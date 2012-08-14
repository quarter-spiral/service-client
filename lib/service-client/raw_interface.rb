require 'uri'

module Service
  class Client
    class RawInterface
      def initialize(client)
        @client = client
      end

      def get(url, body, options)
        request(:get, url, body, options)
      end

      def put(url, body, options)
        request(:put, url, body, options)
      end

      def post(url, body, options)
        request(:post, url, body, options)
      end

      def delete(url, body, options)
        request(:delete, url, body, options)
      end

      def adapter
        @adapter ||= default_adapter
      end

      def adapter=(new_adapter)
        @adapter = new_adapter
      end

      def request(method, url, body, options)
        adapter.request(method, absolutize_url(url), body, options)
      end

      protected
      def default_adapter
        Adapter::Faraday.new
      end

      def absolutize_url(url)
        URI::join(@client.base_url, url).to_s
      end
    end
  end
end
