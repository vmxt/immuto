# Immuto

Immuto helps you create small immutable value objects in Ruby.

It is framework-agnostic and works with plain Ruby classes. Include `Immuto`, declare attributes, and every instance becomes a frozen object with reader methods, defaults, value-based equality, and safe copy updates.

## Installation

Add Immuto to your Gemfile:

```ruby
gem "immuto"
```

Then install:

```bash
bundle install
```

## Quick Start

```ruby
class User
  include Immuto

  attribute :name
  attribute :age
end

user = User.new(name: "Jeff", age: 24)
updated = user.with(age: 25)

user.age
#=> 24

updated.age
#=> 25
```

The original object does not change. `with` returns a new object with the requested changes.

## Attributes

Declare attributes with `attribute`.

```ruby
class Post
  include Immuto

  attribute :title
  attribute :published
end
```

Attributes are available as readers:

```ruby
post = Post.new(title: "Hello", published: false)

post.title
#=> "Hello"
```

Writer methods are not generated:

```ruby
post.respond_to?(:title=)
#=> false
```

Attributes without defaults are required:

```ruby
Post.new(title: "Hello")
# raises Immuto::MissingAttributeError
```

Passing `nil` explicitly is allowed:

```ruby
Post.new(title: "Hello", published: nil)
```

## Defaults

Use `default:` for optional attributes.

```ruby
class User
  include Immuto

  attribute :name
  attribute :active, default: true
end

user = User.new(name: "Jeff")

user.active
#=> true
```

Callable defaults are evaluated when a new object is created.

```ruby
class Session
  include Immuto

  attribute :id, default: -> { SecureRandom.uuid }
  attribute :tags, default: -> { [] }
end
```

Use callable defaults for values that should be fresh for each instance.

## Immutability

Objects are frozen after initialization.

```ruby
user = User.new(name: "Jeff", age: 24)

user.frozen?
#=> true
```

To change a value, create an updated copy:

```ruby
older_user = user.with(age: 25)
```

## Equality

Two Immuto objects are equal when they have the same class and the same attribute values.

```ruby
User.new(name: "Jeff", age: 24) == User.new(name: "Jeff", age: 24)
#=> true

User.new(name: "Jeff", age: 24) == User.new(name: "Jeff", age: 25)
#=> false
```

## Unknown Attributes

Immuto raises an error when you initialize or update an object with an attribute that was not declared.

```ruby
User.new(name: "Jeff", email: "jeff@example.com")
# raises Immuto::UnknownAttributeError

user.with(email: "jeff@example.com")
# raises Immuto::UnknownAttributeError
```

## Inspecting Objects

`inspect` shows the declared attributes and their values.

```ruby
user = User.new(name: "Jeff", active: true)

user.inspect
#=> #<User name="Jeff" active=true>
```

## Development

Install dependencies:

```bash
bin/setup
```

Run the test suite:

```bash
bundle exec rake
```

Open a console:

```bash
bin/console
```

## License

Immuto is available as open source under the terms of the MIT License.
