# Immuto

Immuto is a framework-agnostic immutable object toolkit for Ruby.

This is the Day 1 MVP for `v0.1.0`: immutable attributes, object freezing, `with`, and equality.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "immuto"
```

Then execute:

```bash
bundle install
```

## Usage

```ruby
class User
  include Immuto

  attribute :name
  attribute :age
end

user = User.new(
  name: "Jeff",
  age: 24
)

updated = user.with(age: 25)

user.age
#=> 24

updated.age
#=> 25
```

Declared attributes are exposed as readers only. Instances are frozen after initialization.

```ruby
user.frozen?
#=> true

user.respond_to?(:age=)
#=> false
```

Objects compare equal when they have the same class and the same declared attribute values.

```ruby
User.new(name: "Jeff", age: 24) == User.new(name: "Jeff", age: 24)
#=> true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Immuto project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the code of conduct.
