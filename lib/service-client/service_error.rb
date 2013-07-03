class Service::Client::ServiceError < Service::Client::Error
  attr_reader :error

  def initialize(error)
    super(error)
    @error = error
  end
end
