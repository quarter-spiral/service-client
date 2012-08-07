require 'uri'

module Service
  class Client
    class RawInterface
      def initialize(client)
        @client = client

        [:get, :put, :post, :delete].each do |method|
          self.class.send(:define_method, method) do |url, body = nil, options = {}|
            self.request(method, url, body, options)
          end
        end
      end

      def adapter
        @adapter ||= default_adapter
      end

      def adapter=(new_adapter)
        @adapter = new_adapter
      end

      protected
      def default_adapter
        nil
      end

      def request(method, url, body, options)
        adapter.request(method, absolutize_url(url), body, options)
      end

      def absolutize_url(url)
        URI::join(@client.base_url, url).to_s
      end
    end
  end
end
