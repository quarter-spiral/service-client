require_relative './spec_helper'
require 'json'

def must_send_request(method, url, json = nil, options = {}, &blck)
  @client.raw.adapter.expect :request, true, [method, url, json ? JSON.dump(json) : '', options]
  yield
  @client.raw.adapter.verify
  @client.raw.adapter = MiniTest::Mock.new
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
    Service::Client.new('http://example.com').raw.adapter.must_equal Service::Client::Adapter::Faraday
  end

  describe "high level interface" do
    before do
      @client.urls.add(:author, :post, '/authors/')
      @client.urls.add(:author, :get,  '/authors/:id:')
      @client.urls.add(:review, :post,  '/authors/:author_id:/books/:book_id:')
    end

    it "calls the right url with the right method after adding it" do
      must_send_request(:post, 'http://example.com/authors/', name: 'Peter Lustig') do
        @client.post(@client.urls.author, name: 'Peter Lustig')
      end

      must_send_request(:get, 'http://example.com/authors/123') do
         @client.get(@client.urls.author(123))
      end

      must_send_request(:post, 'http://example.com/authors/123/books/456', name: 'Ronald Review', comment: 'This book is the bomb!') do
        @client.post(@client.urls.review(author_id: 123, book_id: 456), name: 'Ronald Review', comment: 'This book is the bomb!')
      end

      must_send_request(:post, 'http://example.com/authors/123/books/456', name: 'Ronald Review', comment: 'This book is the bomb!') do
        @client.post(@client.urls.review(123, 456), name: 'Ronald Review', comment: 'This book is the bomb!')
      end
    end

    it "raises an error when no route for a given method/resource combination exist" do
      lambda {
        @client.post(@client.urls.author(123))
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.author)
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.review(123, 456), name: 'Ronald Review', comment: 'This book is the bomb!')
      }.must_raise Service::Client::RoutingError

      lambda {
        @client.get(@client.urls.comments)
      }.must_raise Service::Client::RoutingError
    end
  end
end
