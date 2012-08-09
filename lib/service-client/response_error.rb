class Service::Client::ResponseError < Service::Client::Error
  attr_reader :response

  def initialize(response)
    @response = response
  end
end
