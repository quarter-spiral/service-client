require_relative '../spec_helper'
require 'realweb'
require 'json'

describe Service::Client::Adapter::Faraday do
  before do
    $__service_client_test_server ||= RealWeb.start_server_in_thread(File.expand_path("../test_server.ru", __FILE__))
    @server = $__service_client_test_server
    @url = @server.base_uri.to_s
    @adapter = Service::Client::Adapter::Faraday.new
  end

  after do
    unless $__service_client_stop_defined
      self.class.class_eval do
        at_exit do
          puts "Shutting down server"
          $__service_client_test_server.stop
        end
      end
    end
    $__service_client_stop_defined = true
  end

  headers = {
    'USER-AGENT' => 'service-client-spec',
    'REFERER' => 'http://super.example.com/'
  }
  body = 'This is a test'
  [:get, :put, :post, :delete].each do |method|
    it "sends correct #{method} requests" do
      response = @adapter.request(method, @url, body, {headers: headers})
      response.status.must_equal 200
      request = JSON.parse(response.body.first)
      request['body'].must_equal body
      request['method'].must_equal method.to_s.upcase
      headers.each do |key, value|
        request['headers'][key].must_equal value
      end
    end
  end

  it "can use other Faraday adapters" do
    ran = false
    app = lambda {|env| ran = true; [200, {'Content-Type' => 'text/html'}, ["ran"]]}
    adapter = Service::Client::Adapter::Faraday.new(adapter: [:rack, app])
    adapter.request(:get, 'http://example.com/adapter_change', '', {})
    ran.must_equal true
  end

  describe 'faraday builder' do
    it 'can be used' do
      ran = false
      builder_called = false
      app = lambda {|env| ran = true; [200, {'Content-Type' => 'text/html'}, ["ran"]]}
      adapter = Service::Client::Adapter::Faraday.new(adapter: [:rack, app], builder: lambda {|faraday| builder_called = true})
      adapter.request(:get, 'http://example.com/adapter_change', '', {})
      ran.must_equal true
      builder_called.must_equal true
    end

    it 'can skip the adapter call' do
      ran = false
      builder_called = false
      app = lambda {|env| ran = true; [200, {'Content-Type' => 'text/html'}, ["ran"]]}
      adapter = Service::Client::Adapter::Faraday.new(adapter: [:rack, app], builder: lambda {|faraday| builder_called = true; false})
      adapter.request(:get, 'http://example.com/adapter_change', '', {})
      # must be false because the rack adapter is not used as the builder returns false
      ran.must_equal false
      builder_called.must_equal true
    end
  end
end
