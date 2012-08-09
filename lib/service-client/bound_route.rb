class Service::Client::BoundRoute
  def initialize(route, args)
    @route = route
    @args = args || []
  end

  def url_for_method(method)
    pattern = @route.pattern_for(method)

    raise Service::Client::RoutingError.new("Method #{method} unsupported!") unless pattern

    pattern.filled_with(options_for_pattern(pattern))
  end

  protected
  def options_for_pattern(pattern)
    if args_are_a_hash?
      @args.first
    else
      options_for_pattern_from_args_array(pattern)
    end
  end

  def args_are_a_hash?
    @args.size == 1 && @args.first.kind_of?(Hash)
  end

  def options_for_pattern_from_args_array(pattern)
    if @args.size != pattern.placeholders.size
      raise Service::Client::RoutingError.new("Number of URL arguments does not match! Given: #{@args.inspect} Expected: #{pattern.placeholders.inspect}")
    end

    cloned_args = @args.clone
    options = {}
    pattern.placeholders.each do |placeholder|
      options[placeholder] = cloned_args.shift
    end
    options
  end
end
