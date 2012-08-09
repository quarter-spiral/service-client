class Service::Client::Route
  def add_pattern(method, pattern)
    patterns[method] = Service::Client::UrlPattern.new(pattern)
  end

  def bind(*args)
    Service::Client::BoundRoute.new(self, args)
  end

  def pattern_for(method)
    patterns[method]
  end

  protected
  def patterns
    @patterns ||= {}
  end
end
