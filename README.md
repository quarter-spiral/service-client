# Service::Client

Service::Client is a generic client gem to access our services. It is the base for explicit clients for each service so that those explicit clients are easy and fast to implement and maintain.

This gem should not be used as an "end-user solution".

## Usage

### Client creation

Each client must be instantiated with a base URL to a service.

```ruby
client = Service::Client.new('http://some=service.example.com/')
```

### Creating routes

A client route describes a single REST HTTP end-point at the service.

```ruby
client.urls.add(:author, :post, '/authors/')
client.urls.add(:author, :get,  '/authors/:id:')
client.urls.add(:review, :post,  '/author/:author_id:/books/:book_id:')
```

### Requests

```ruby
client.post(client.urls.author, name: 'Peter Lustig')
client.get(client.urls.author(123))
client.post(client.urls.review(author_id: 123, book_id: 456), name: 'Ronald Review', comment: 'This book is the bomb!')
```

Each ``Service::Client`` instance supports the ``get``, ``post``, ``put`` and ``delete`` methods. They all share the same method signature of:

```ruby
client.method(URL, BODY_HASH)
```

The URL is a relative URL to the base url the client has been created with. The BODY_HASH is any Ruby hash. The hash becomes the body of the HTTP request after it has been dumped to JSON.

The ``client.urls`` method makes all the created routes available as an easy to use URL builder. The URL builder takes zero arguments when the URL does not have any arguments. It can also take an array of the URL paramters in their respective order or a hash to built the URL by it's named parameters.

### Response

If the HTTP response comes with a 200 status code, the client returns a ``Service::Client::Response`` object. That allows you to query for the JSON decoded data that came along with the body of the HTTP response. If the body was empty that data is just ``true``. You can also reach for the raw HTTP response:

```ruby
response = client.get(client.urls.author(123))
puts "retrieved a book written by #{response.data['name']} with an HTTP status code of #{response.raw.status}"
```

For any redirecting responses the client raises a ``Service::Client::Redirection`` which can be queried for the redirection location:

```ruby
begin
  client.get(client.urls.author(123))
rescue Client::Service::Redirection => redirection
  puts "The client has been redirected to: #{redirection.location}"
end
```

For any other response codes the client raises a ``Service::Client::ServiceError`` if the response body was a JSON encoded object with an ``error`` key on the root level.

```ruby
begin
  client.get(client.urls.author(678))
rescue Client::Service::ServiceError => e
  puts "A service error has occured. Error description: #{e.error}"
end
```

If the body was not JSON encoded at all or did not include the ``error`` key on the root level a ``Service::Client::Error`` is raised.

```ruby
begin
  client.get(client.urls.author(678))
rescue Client::Service::Error => e
  puts "An error has occured. Error code: #{e.response.status} Error body: #{e.response.body}"
end
```

### Raw HTTP requests

The client exposes an interface that can be used to issue raw HTTP requests to any URL relative to the given base URL at creation time.

```ruby
response = client.raw.post('/authors/123/books', JSON.dump({title: 'The guide to a higher enlightment', isbn: '1234567'}))
```

The raw client supports the ``get``, ``post``, ``put`` and ``delete`` methods. They all share the same method signature of:

```ruby
client.raw.method(URL, BODY, OPTIONS)
```

The options are a hash. Possible arguments are:

* **``headers``**: A hash (string:string) to set the request headers.

### Raw responses

Raw requests return a ``Rack::Response`` object that makes it easy to access the status code, headers and body of the response.

```ruby
response = client.raw.get('/author/123/books')
response.body   # "[{title: 'The guide to a higher enlightment', isbn: '1234567', id: 456}, {title: 'Some book', isbn: '23464527', id: 789}]"
response.status # 200
response.header # {"Some-Header" => "Some Value", "Another-Header" => "Another Value"}
```
