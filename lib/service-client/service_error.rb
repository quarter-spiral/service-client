class Service::Client::ServiceError < Service::Client::Error
  attr_reader :error

  def initialize(error)
    @error = error
  end
end
