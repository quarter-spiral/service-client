require_relative './spec_helper'
require 'json'

TOKEN = '123'

def must_send_request(method, url, json = nil, options = {}, &blck)
  @client.raw.adapter.expect :request, Rack::Response.new('', 200, {}), [method, url, json ? JSON.dump(json) : nil, options]
  yield
  @client.raw.adapter.verify
  @client.raw.adapter = MiniTest::Mock.new
end

def must_raise_response_error(body)
  raw_response = Rack::Response.new(body, 500, {})
  @client.raw.adapter.expect :request, raw_response, [:get, 'http://example.com/authors/123', body, {}]
  begin
    @client.get(@client.urls.author(123), TOKEN)
    flunk "Must raise Service::Client::ResponseError but didn't!"
   rescue Service::Client::ResponseError => e
     e.response.status.must_equal 500
     e.response.body.must_equal [body]
   end
end

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

  it "uses the faraday adapter as a default" do
    Service::Client.new('http://example.com').raw.adapter.must_be_instance_of Service::Client::Adapter::Faraday
  end

  describe "high level interface" do
    before do
      @client.urls.add(:author, :post, '/authors/')
      @client.urls.add(:author, :get,  '/authors/:id:')
      @client.urls.add(:author_with_query, :get,  '/authors/:id:/another-fixed-part?blub=1')
      @client.urls.add(:review, :post,  '/authors/:author_id:/books/:book_id:')
    end

    it "calls the right url with the right method after adding it" do
      must_send_request(:post, 'http://example.com/authors/', {name: 'Peter Lustig'}, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.post(@client.urls.author, TOKEN, name: 'Peter Lustig')
      end

      must_send_request(:get, 'http://example.com/authors/123', nil, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.get(@client.urls.author(123), TOKEN)
      end

      must_send_request(:post, 'http://example.com/authors/123/books/456', {name: 'Ronald Review', comment: 'This book is the bomb!'}, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.post(@client.urls.review(author_id: 123, book_id: 456), TOKEN, name: 'Ronald Review', comment: 'This book is the bomb!')
      end

      must_send_request(:post, 'http://example.com/authors/123/books/456', {name: 'Ronald Review', comment: 'This book is the bomb!'}, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.post(@client.urls.review(123, 456), TOKEN, name: 'Ronald Review', comment: 'This book is the bomb!')
      end
    end

    it "uses query parameters instead of JSON bodies for GET requests" do
      must_send_request(:get, 'http://example.com/authors/123?some=arguments&are=cool%26not%3Dbody', nil, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.get(@client.urls.author(123), TOKEN, {some: 'arguments', are: "cool&not=body"})
      end

      must_send_request(:get, 'http://example.com/authors/123/another-fixed-part?blub=1&some=arguments&are=cool%26not%3Dbody', nil, headers: {'AUTHORIZATION' => "Bearer #{TOKEN}"}) do
        @client.get(@client.urls.author_with_query(123), TOKEN, {some: 'arguments', are: "cool&not=body"})
      end
    end


    it "raises an error when no route for a given method/resource combination exist" do
      lambda {
        @client.post(@client.urls.author(123), TOKEN)
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.author, TOKEN)
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.review(123, 456), TOKEN, name: 'Ronald Review', comment: 'This book is the bomb!')
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.comments, TOKEN)
      }.must_raise Service::Client::RoutingError
    end

    describe "responses" do
      describe "successful" do
        statuses = [200, 201]
        statuses.each do |status|
          describe "with status #{status}" do
            before do
              @body = JSON.dump(name: 'Peter Lustig', age: 76)
              @headers = {}
              raw_response = Rack::Response.new(@body, status, @headers)
              @client.raw.adapter.expect :request, raw_response, [:get, 'http://example.com/authors/123', '', {}]
              @response = @client.get(@client.urls.author(123), TOKEN)
            end

            it "has the raw data" do
              @response.raw.status.must_equal status
              @response.raw.body.must_equal [@body]
              @headers.each do |key, value|
                @response.raw.header[key].must_equal value
              end
            end

            it "parses them" do
              @response.data['name'].must_equal 'Peter Lustig'
              @response.data['age'].must_equal 76
            end

            it "returns true for data if the response is empty" do
              raw_response = Rack::Response.new('', status, {})
              @client.raw.adapter.expect :request, raw_response, [:get, 'http://example.com/authors/456', '', {}]
              @response = @client.get(@client.urls.author(456), TOKEN)
              @response.data.must_equal true
            end
          end
        end
      end

      describe "redirections" do
        statuses = [301, 302, 303, 307]
        statuses.each do |status|
          it "raises a Service::Client::Redirection with the location for HTTP status #{status}" do
            @client.raw.adapter.expect :request, Rack::Response.new('', status, {Location: 'http://example.com/somewhere/else'}), [:get, 'http://example.com/authors/123', '', {}]

            begin
              @client.get(@client.urls.author(123), TOKEN)
              flunk "Must raise Service::Client::Redirection but didn't!"
            rescue Service::Client::Redirection => e
              e.location.must_equal 'http://example.com/somewhere/else'
            end
          end
        end
      end

      describe "errors" do
        describe "when error field is present" do
          before do
            @body = JSON.dump(error: 'This is why!')
          end

          error_states = [400, 401, 403, 404, 500]
          error_states.each do |error_state|
            it "raises an Service::Client::ServiceError for HTTP status code #{error_state}" do
              raw_response = Rack::Response.new(@body, error_state, {})
              @client.raw.adapter.expect :request, raw_response, [:get, 'http://example.com/authors/123', @body, {}]

              begin
                @client.get(@client.urls.author(123), TOKEN)
                flunk "Must raise Service::Client::ServiceError but didn't!"
              rescue Service::Client::ServiceError => e
                e.error.must_equal 'This is why!'
              end
            end
          end
        end

        describe "raises Service::Client::ResponseError when body is" do
          it "empty" do
            must_raise_response_error('')
          end

          it "invalid JSON" do
            must_raise_response_error('some stuff but not json')
          end

          it "valid JSON but has no error field" do
            must_raise_response_error(JSON.dump(missing: 'error', field: true))
          end
        end
      end
    end
  end
end
