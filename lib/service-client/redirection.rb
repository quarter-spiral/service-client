class Service::Client::Redirection < Exception
  include Service::Client::BaseResponse

  def location
    raw.header.detect {|k,v| k.to_s.downcase == 'location'}.last
  end
end
