require "service-client/version"
require "service-client/raw_interface"

module Service
  class Client
    attr_reader :base_url

    def initialize(base_url)
      @base_url = base_url
    end

    def raw
      @raw_interface ||= RawInterface.new(self)
    end
  end
end
