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

## Validation

Use `validate:` to reject invalid values.

```ruby
class User
  include Immuto

  attribute :name
  attribute :age, validate: ->(value) { value >= 0 }
end

User.new(name: "Jeff", age: -1)
# raises Immuto::ValidationError
```

Use `message:` to customize the error.

```ruby
class User
  include Immuto

  attribute :age,
            validate: ->(value) { value >= 0 },
            message: "must be greater than or equal to 0"
end

User.new(age: -1)
# raises Immuto::ValidationError:
# validation failed for :age: must be greater than or equal to 0
```

Validation runs whenever Immuto builds a new object, including `new`, `with`, `with_path`, and `from_h`.

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

## Nested Updates

Use `with_path` to update an immutable object inside another immutable object.

```ruby
class Profile
  include Immuto

  attribute :display_name
  attribute :timezone
end

class Account
  include Immuto

  attribute :profile
  attribute :plan
end

account = Account.new(
  profile: Profile.new(display_name: "Jeff", timezone: "UTC"),
  plan: "free"
)

updated = account.with_path(:profile, :display_name, "Ada")

account.profile.display_name
#=> "Jeff"

updated.profile.display_name
#=> "Ada"

updated.profile.timezone
#=> "UTC"
```

`with_path` can update deeper paths too.

```ruby
updated = account.with_path(:profile, :settings, :theme, "dark")
```

Objects along the updated path are rebuilt. Unchanged values are reused.

## Serialization

Use `to_h` to turn an immutable object into a plain Ruby hash.

```ruby
user = User.new(name: "Jeff", age: 24)

user.to_h
#=> { name: "Jeff", age: 24 }
```

Nested Immuto objects are serialized as nested hashes.

```ruby
account.to_h
#=> {
#     profile: { display_name: "Ada", timezone: "UTC" },
#     plan: "free"
#   }
```

Use `to_json` when you need a JSON string.

```ruby
user.to_json
#=> "{\"name\":\"Jeff\",\"age\":24}"
```

Use `from_h` to build an immutable object from a hash.

```ruby
user = User.from_h("name" => "Jeff", "age" => 24)

user.name
#=> "Jeff"
```

`from_h` applies defaults and raises the same missing or unknown attribute errors as `new`.

Nested hashes are not converted into nested classes automatically. Build nested objects first when you need them.

```ruby
profile = Profile.from_h(display_name: "Ada", timezone: "UTC")
account = Account.from_h(profile: profile, plan: "free")
```

## Diffing

Use `diff` to compare two objects of the same class.

```ruby
user = User.new(name: "Jeff", age: 24)
updated = user.with(age: 25)

user.diff(updated)
#=> {
#     age: { from: 24, to: 25 }
#   }
```

Nested Immuto objects are diffed recursively.

```ruby
account.diff(updated_account)
#=> {
#     profile: {
#       display_name: { from: "Jeff", to: "Ada" }
#     }
#   }
```

Arrays and hashes are compared by value.

Diffing requires two objects of the same class.

```ruby
user.diff(Object.new)
# raises Immuto::DiffError
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

Nested updates must pass through values that support `with_path`.

```ruby
user.with_path(:name, :first, "Ada")
# raises Immuto::NestedUpdateError
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
