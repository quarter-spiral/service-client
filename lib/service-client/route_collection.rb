class Service::Client::RouteCollection
  def add(name, method, pattern)
    name = name.to_sym

    route = routes[name] ||= Service::Client::Route.new
    route.add_pattern(method, pattern)
  end

  protected
  def routes
    @routes ||= {}
  end

  def method_missing(name, *args)
    raise Service::Client::RoutingError.new("No route named #{name}") unless route = routes[name.to_sym]
    route.bind(*args)
  end
end
