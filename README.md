# Immuto

Immuto is a tiny Ruby helper for objects that stay put.

You tell an object what bits it has, Immuto freezes it, and any update gives you
a fresh copy. The old one stays exactly how it was.

Made for side-project code where simple, calm little value objects feel nicer
than dragging in a whole framework.

## The Vibe

- one `include Immuto`
- declare a few attributes
- frozen objects by default
- update with `with`
- nested updates with `with_path`
- frozen arrays and hashes when you want them
- hash, JSON, diff, merge, and snapshots when needed

## Install

```ruby
gem "immuto"
```

```bash
bundle install
```

## Tiny Taste

```ruby
class Trinket
  include Immuto

  attribute :label
  attribute :aura, default: "glowy"
  attribute :rarity, validate: ->(value) { value >= 1 }
end

first = Trinket.new(label: "pocket star", rarity: 2)
upgraded = first.with(rarity: 3)

first.rarity
#=> 2

upgraded.to_h
#=> { label: "pocket star", aura: "glowy", rarity: 3 }
```

`first` did not change. `upgraded` is a new frozen object.

## Creating and Updating

```ruby
from_hash = Trinket.from_h("label" => "pocket star", "rarity" => 2)

built = Trinket.build do
  label "moon pebble"
  rarity 3
end

polished = built.rebuild do
  rarity 4
end
```

`from_h` accepts a hash-like value, including hashes with string keys.
`build` creates an object from a block, while `rebuild` starts with the
current values and returns a new object containing the block's changes.
Both methods apply defaults and validation just like `new`.

Use `with` for top-level changes and `with_path` to update a nested Immuto
object:

```ruby
class Shelf
  include Immuto

  attribute :favorite
end

shelf = Shelf.new(favorite: first)
updated_shelf = shelf.with_path(:favorite, :aura, "moonlit")
```

`with` and `rebuild` return the original object when called without changes.
Otherwise they return a new frozen object.

## Types and Validation

Attributes can enforce a type or coerce an input before type and custom
validation:

```ruby
require "time"

class Event
  include Immuto

  attribute :age, type: Integer
  attribute :created_at, type: Time, coerce: ->(value) { Time.parse(value) }
  attribute :title, validate: ->(value) { !value.empty? }, message: "can't be blank"
end

event = Event.new(age: 42, created_at: "2026-10-17 10:00:00 UTC", title: "Meetup")
event.created_at
#=> a Time instance
```

Use `coerce` when inputs should be converted; `type` checks the value after
coercion. For example, `age: "42"` raises `Immuto::ValidationError` because no
coercion was declared for `age`. Failed coercion, type checks, and custom
validation also raise `Immuto::ValidationError`. Attributes without defaults
are required, but may be explicitly set to `nil`.

## Frozen Collections and Serialization

The object itself is frozen, but arbitrary values stored in its attributes
are not automatically deep-frozen. Use the collection helpers when you want a
detached, deeply frozen array or hash:

```ruby
tags = Immuto.array("ruby", "tiny")
meta = Immuto.hash(status: "draft", tags: ["ruby"])
```

`to_h` converts nested Immuto objects and collections containing them to
ordinary Ruby hashes and arrays. `to_json` serializes that hash as JSON.

## Diffs, Merging, and Snapshots

`diff` describes changed attributes, recursing into nested Immuto objects.
`merge` returns a new object of the same class, preferring values from the
incoming object and recursively merging nested Immuto objects. Arrays and
hashes are replaced by the incoming value.

```ruby
first.diff(upgraded)
#=> { rarity: { from: 2, to: 3 } }

merged = first.merge(upgraded)
#=> a new Trinket with upgraded's values

snapshot = first.snapshot
upgraded.changes_since(snapshot)
#=> { rarity: { from: 2, to: 3 } }

restored = Trinket.restore(snapshot)
```

Snapshots contain a frozen serialized copy of an object. Restore them through
the class that created them; using a snapshot from another class raises
`Immuto::SnapshotError`.

## Local Play

```bash
bin/setup
bundle exec rake
bin/console
```

## License

MIT. Make something small and useful.
