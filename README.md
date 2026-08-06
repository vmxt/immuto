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

## Extra Bits

```ruby
snapshot = first.snapshot

first.diff(upgraded)
#=> { rarity: { from: 2, to: 3 } }

restored = Trinket.restore(snapshot)
```

Frozen collections are there for attributes that hold arrays or hashes:

```ruby
tags = Immuto.array("ruby", "tiny")
meta = Immuto.hash(status: "draft")
```

Nested objects can be nudged too:

```ruby
class Shelf
  include Immuto

  attribute :favorite
end

shelf = Shelf.new(favorite: first)
updated_shelf = shelf.with_path(:favorite, :aura, "moonlit")
```

## Local Play

```bash
bin/setup
bundle exec rake
bin/console
```

## License

MIT. Make something small and useful.
