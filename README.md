# Immuto

Immuto is a tiny Ruby gem for making little objects that do not mutate.

Basically: you define the fields once, create the object, and then any "change"
gives you a new copy instead of messing with the old one.

I made this because sometimes I want plain Ruby objects that feel predictable
without pulling in a whole framework or writing the same boilerplate again.

## The vibe

- plain Ruby
- include one module
- declare a few attributes
- get frozen objects
- update by copying with `with`
- turn things into hashes or JSON when needed
- diff, merge, and snapshot objects if you want to get fancy

Not a huge architecture thing. Just a small helper for value-object style code.

## Install

Add it to your `Gemfile`:

```ruby
gem "immuto"
```

Then:

```bash
bundle install
```

## Tiny example

```ruby
class User
  include Immuto

  attribute :name
  attribute :age
end

user = User.new(name: "Jeff", age: 24)
older = user.with(age: 25)

user.age
#=> 24

older.age
#=> 25
```

The first object stays the same. `with` returns a new frozen copy.

## Defaults

```ruby
class Account
  include Immuto

  attribute :name
  attribute :active, default: true
end

account = Account.new(name: "side project")

account.active
#=> true
```

If the default should be fresh each time, use a lambda:

```ruby
class Session
  include Immuto

  attribute :id, default: -> { SecureRandom.uuid }
  attribute :tags, default: -> { [] }
end
```

## Simple checks

You can add a small validation lambda:

```ruby
class User
  include Immuto

  attribute :name
  attribute :age, validate: ->(value) { value >= 0 }
end

User.new(name: "Jeff", age: -1)
# raises Immuto::ValidationError
```

Custom message if you care:

```ruby
attribute :age,
          validate: ->(value) { value >= 0 },
          message: "must be 0 or more"
```

## Block builder

Sometimes this reads nicer than passing a hash:

```ruby
user = User.build do
  name "Jeff"
  age 24
end
```

And you can rebuild from an existing object:

```ruby
older = user.rebuild do
  age 25
end
```

## Nested updates

For objects inside objects, `with_path` saves a bit of typing:

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
```

Only the changed path is rebuilt. The rest stays as-is.

## Hashes and JSON

```ruby
user = User.new(name: "Jeff", age: 24)

user.to_h
#=> { name: "Jeff", age: 24 }

user.to_json
#=> "{\"name\":\"Jeff\",\"age\":24}"
```

You can also build from a hash:

```ruby
user = User.from_h("name" => "Jeff", "age" => 24)
```

Nested hashes are not magically converted into nested classes. Build those
objects yourself first.

## Diff and merge

Diff shows what changed:

```ruby
user = User.new(name: "Jeff", age: 24)
older = user.with(age: 25)

user.diff(older)
#=> { age: { from: 24, to: 25 } }
```

Merge takes another object of the same class and lets the incoming values win:

```ruby
base = User.new(name: "Jeff", age: 24)
incoming = User.new(name: "Jeff", age: 25)

base.merge(incoming).age
#=> 25
```

Nested Immuto objects diff and merge recursively.

## Snapshots

Snapshots are frozen copies of the serialized state:

```ruby
user = User.new(name: "Jeff", age: 24)
snapshot = user.snapshot

older = user.with(age: 25)

older.changes_since(snapshot)
#=> { age: { from: 24, to: 25 } }
```

You can restore from one too:

```ruby
restored = User.restore(snapshot)
```

## Stuff it complains about

Immuto is small, but it does try to catch the obvious mistakes:

- missing required attributes
- unknown attributes
- invalid values from `validate:`
- diffing or merging different classes
- nested updates through something that is not an Immuto object

## Playing with it locally

```bash
bin/setup
bundle exec rake
bin/console
```

## License

MIT. Have fun with it.
