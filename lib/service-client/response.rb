require 'json'

class Service::Client::Response
  include Service::Client::BaseResponse

  attr_reader :data

  def initialize(raw_response)
    super(raw_response)
    body = raw.body.first
    @data = body.empty? ? true : JSON.parse(body)
  end
end
