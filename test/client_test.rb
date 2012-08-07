require_relative './test_helper'

describe Service::Client do
  before do
    @client = Service::Client.new('http://example.com')
    @client.raw.adapter = MiniTest::Mock.new
  end

  describe "raw interface" do
    it "is exposed" do
      @client.raw.must_be_instance_of Service::Client::RawInterface
    end

    args = ['/bla', :body, :options]
    url, body, options = args
    [:get, :put, :post, :delete].each do |method|
      it "passes #{method} requests through to the HTTP adapter" do
        @client.raw.adapter.expect :request, true, [method, 'http://example.com/bla', body, options]
        @client.raw.send(method, *args)
        @client.raw.adapter.verify
      end
    end
  end
end
