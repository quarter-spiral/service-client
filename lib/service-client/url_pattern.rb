class Service::Client::UrlPattern
  def initialize(pattern)
    @pattern = pattern
    @pattern.scan(/:([^:]+):/).each do |placeholder|
      placeholders << placeholder.first.to_sym
    end
  end

  def filled_with(options)
    url = @pattern.clone
    placeholders.each do |placeholder|
      url.gsub!(/:#{Regexp.escape(placeholder)}:/, options[placeholder].to_s)
    end
    url
  end

  def placeholders
    @placeholders ||= []
  end
end
