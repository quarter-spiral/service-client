module Service::Client::BaseResponse
  def initialize(raw_response)
    @raw_response = raw_response
  end

  def raw
    @raw_response
  end
end
