require 'json'

run lambda {|env|
  request = Rack::Request.new(env)
  method = request.request_method
  headers = Hash[env.select {|k,v| k =~ /^HTTP_/}.map {|k,v| [k.gsub(/^HTTP_/, '').gsub('_', '-'), v]}]
  body = request.body.read
  [200, { 'Content-Type' => 'application/json' }, [JSON.dump(
    method: method,
    headers: headers,
    body: body
  )]]
}
