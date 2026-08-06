# frozen_string_literal: true

RSpec.describe Immuto do
  let(:user_class) do
    Class.new do
      include Immuto

      attribute :name
      attribute :age
    end
  end

  it "has a version number" do
    expect(Immuto::VERSION).not_to be nil
  end

  it "defines immutable readers for declared attributes" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
    expect(user).not_to respond_to(:name=)
    expect(user).not_to respond_to(:age=)
  end

  it "accepts string keys" do
    user = user_class.new(**{ "name" => "Jeff", "age" => 24 })

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
  end

  it "freezes created objects" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user).to be_frozen
    expect { user.instance_variable_set(:@age, 25) }.to raise_error(FrozenError)
  end

  it "returns an updated immutable copy with with" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.with(age: 25)

    expect(user.age).to eq(24)
    expect(updated.age).to eq(25)
    expect(updated.name).to eq("Jeff")
    expect(updated).to be_a(user_class)
    expect(updated).to be_frozen
  end

  it "returns itself when with is called without changes" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.with).to be(user)
  end

  it "updates a nested immutable object with with_path" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
      attribute :timezone
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
      attribute :plan
    end

    profile = profile_class.new(display_name: "Jeff", timezone: "UTC")
    account = account_class.new(profile:, plan: "free")
    updated = account.with_path(:profile, :display_name, "Ada")

    expect(account.profile.display_name).to eq("Jeff")
    expect(updated.profile.display_name).to eq("Ada")
    expect(updated.profile.timezone).to eq("UTC")
    expect(updated.plan).to eq("free")
    expect(updated).to be_frozen
    expect(updated.profile).to be_frozen
  end

  it "reuses unchanged nested branches during nested updates" do
    address_class = Class.new do
      include Immuto

      attribute :city
    end

    profile_class = Class.new do
      include Immuto

      attribute :display_name
      attribute :address
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
      attribute :plan
    end

    address = address_class.new(city: "Manila")
    profile = profile_class.new(display_name: "Jeff", address:)
    account = account_class.new(profile:, plan: "free")
    updated = account.with_path(:profile, :display_name, "Ada")

    expect(updated).not_to be(account)
    expect(updated.profile).not_to be(profile)
    expect(updated.profile.address).to be(address)
    expect(updated.plan).to be(account.plan)
  end

  it "updates deeper nested immutable objects with with_path" do
    address_class = Class.new do
      include Immuto

      attribute :city
    end

    profile_class = Class.new do
      include Immuto

      attribute :address
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    address = address_class.new(city: "Manila")
    profile = profile_class.new(address:)
    account = account_class.new(profile:)
    updated = account.with_path(:profile, :address, :city, "Cebu")

    expect(account.profile.address.city).to eq("Manila")
    expect(updated.profile.address.city).to eq("Cebu")
    expect(updated.profile).not_to be(profile)
    expect(updated.profile.address).not_to be(address)
  end

  it "accepts string keys in nested update paths" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(profile: profile_class.new(display_name: "Jeff"))
    updated = account.with_path("profile", "display_name", "Ada")

    expect(updated.profile.display_name).to eq("Ada")
  end

  it "updates top-level attributes with with_path" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.with_path(:age, 25)

    expect(user.age).to eq(24)
    expect(updated.age).to eq(25)
  end

  it "serializes declared attributes to a hash" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.to_h).to eq(name: "Jeff", age: 24)
  end

  it "serializes nested immutable objects to hashes" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
      attribute :plan
    end

    account = account_class.new(
      profile: profile_class.new(display_name: "Jeff"),
      plan: "free"
    )

    expect(account.to_h).to eq(
      profile: { display_name: "Jeff" },
      plan: "free"
    )
  end

  it "serializes arrays and hashes containing immutable objects" do
    tag_class = Class.new do
      include Immuto

      attribute :name
    end

    post_class = Class.new do
      include Immuto

      attribute :tags
      attribute :meta
    end

    post = post_class.new(
      tags: [tag_class.new(name: "ruby")],
      meta: { owner: tag_class.new(name: "jeff") }
    )

    expect(post.to_h).to eq(
      tags: [{ name: "ruby" }],
      meta: { owner: { name: "jeff" } }
    )
  end

  it "serializes declared attributes to json" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(JSON.parse(user.to_json)).to eq("name" => "Jeff", "age" => 24)
  end

  it "creates frozen arrays with collection helpers" do
    tags = Immuto.array("ruby", "immutable")

    expect(tags).to eq(%w[ruby immutable])
    expect(tags).to be_frozen
    expect(tags.first).to be_frozen
    expect { tags << "later" }.to raise_error(FrozenError)
  end

  it "creates frozen hashes with collection helpers" do
    meta = Immuto.hash(status: "draft", tags: ["ruby"])

    expect(meta).to eq(status: "draft", tags: ["ruby"])
    expect(meta).to be_frozen
    expect(meta[:status]).to be_frozen
    expect(meta[:tags]).to be_frozen
    expect { meta[:tags] << "later" }.to raise_error(FrozenError)
  end

  it "creates frozen hash copies from hash-like values" do
    meta = Immuto.hash({ "status" => "draft" }, reviewed: false)

    expect(meta).to eq("status" => "draft", reviewed: false)
    expect(meta).to be_frozen
    expect(meta.keys.first).to be_frozen
  end

  it "deep freezes nested collection copies without mutating the original collection" do
    original = { tags: ["ruby"] }
    frozen_copy = Immuto.deep_freeze(original)

    original[:tags] << "mutable"

    expect(original[:tags]).to eq(%w[ruby mutable])
    expect(frozen_copy).to eq(tags: ["ruby"])
    expect(frozen_copy).to be_frozen
    expect(frozen_copy[:tags]).to be_frozen
  end

  it "preserves immutable objects inside frozen collections" do
    user = user_class.new(name: "Jeff", age: 24)
    users = Immuto.array(user)

    expect(users.first).to be(user)
    expect(users).to be_frozen
  end

  it "uses frozen collections as safe defaults" do
    post_class = Class.new do
      include Immuto

      attribute :title
      attribute :tags, default: -> { Immuto.array }
    end

    post = post_class.new(title: "Hello")
    updated = post.with(tags: Immuto.array(*post.tags, "ruby"))

    expect(post.tags).to eq([])
    expect(post.tags).to be_frozen
    expect(updated.tags).to eq(["ruby"])
    expect(updated.tags).to be_frozen
  end

  it "serializes immutable objects inside frozen collections" do
    user = user_class.new(name: "Jeff", age: 24)
    group_class = Class.new do
      include Immuto

      attribute :members
    end

    group = group_class.new(members: Immuto.array(user))

    expect(group.to_h).to eq(members: [{ name: "Jeff", age: 24 }])
  end

  it "raises when creating a hash helper from non-hash-like values" do
    expect { Immuto.hash("nope") }
      .to raise_error(ArgumentError, "hash requires a hash-like object")
  end

  it "returns an empty diff for equal objects" do
    user = user_class.new(name: "Jeff", age: 24)
    same_user = user_class.new(name: "Jeff", age: 24)

    expect(user.diff(same_user)).to eq({})
  end

  it "diffs changed top-level attributes" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.with(age: 25)

    expect(user.diff(updated)).to eq(
      age: { from: 24, to: 25 }
    )
  end

  it "diffs multiple changed attributes" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.with(name: "Ada", age: 25)

    expect(user.diff(updated)).to eq(
      name: { from: "Jeff", to: "Ada" },
      age: { from: 24, to: 25 }
    )
  end

  it "diffs nested immutable objects" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
      attribute :timezone
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
      attribute :plan
    end

    account = account_class.new(
      profile: profile_class.new(display_name: "Jeff", timezone: "UTC"),
      plan: "free"
    )
    updated = account.with_path(:profile, :display_name, "Ada")

    expect(account.diff(updated)).to eq(
      profile: {
        display_name: { from: "Jeff", to: "Ada" }
      }
    )
  end

  it "diffs deeper nested immutable objects" do
    address_class = Class.new do
      include Immuto

      attribute :city
    end

    profile_class = Class.new do
      include Immuto

      attribute :address
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(
      profile: profile_class.new(
        address: address_class.new(city: "Manila")
      )
    )
    updated = account.with_path(:profile, :address, :city, "Cebu")

    expect(account.diff(updated)).to eq(
      profile: {
        address: {
          city: { from: "Manila", to: "Cebu" }
        }
      }
    )
  end

  it "diffs arrays and hashes by value" do
    post_class = Class.new do
      include Immuto

      attribute :tags
      attribute :meta
    end

    post = post_class.new(tags: %w[ruby], meta: { published: false })
    updated = post.with(tags: %w[ruby immutable], meta: { published: true })

    expect(post.diff(updated)).to eq(
      tags: { from: %w[ruby], to: %w[ruby immutable] },
      meta: { from: { published: false }, to: { published: true } }
    )
  end

  it "raises when diffing a different object type" do
    user = user_class.new(name: "Jeff", age: 24)

    expect { user.diff(Object.new) }
      .to raise_error(Immuto::DiffError, "cannot diff #{user_class} with Object")
  end

  it "raises when diffing a different immutable class" do
    other_class = Class.new do
      include Immuto

      attribute :name
      attribute :age
    end
    user = user_class.new(name: "Jeff", age: 24)
    other = other_class.new(name: "Jeff", age: 24)

    expect { user.diff(other) }
      .to raise_error(Immuto::DiffError, "cannot diff #{user_class} with #{other_class}")
  end

  it "merges objects of the same class into a new immutable object" do
    base = user_class.new(name: "Jeff", age: 24)
    incoming = user_class.new(name: "Jeff", age: 25)
    merged = base.merge(incoming)

    expect(merged).to eq(incoming)
    expect(merged).not_to be(base)
    expect(merged).not_to be(incoming)
    expect(merged).to be_frozen
  end

  it "uses incoming values when merging changed top-level attributes" do
    base = user_class.new(name: "Jeff", age: 24)
    incoming = user_class.new(name: "Ada", age: 25)

    merged = base.merge(incoming)

    expect(merged.name).to eq("Ada")
    expect(merged.age).to eq(25)
    expect(base.name).to eq("Jeff")
    expect(base.age).to eq(24)
  end

  it "recursively merges nested immutable objects" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
      attribute :timezone
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
      attribute :plan
    end

    base = account_class.new(
      profile: profile_class.new(display_name: "Jeff", timezone: "UTC"),
      plan: "free"
    )
    incoming = account_class.new(
      profile: profile_class.new(display_name: "Ada", timezone: "UTC"),
      plan: "pro"
    )

    merged = base.merge(incoming)

    expect(merged.profile.display_name).to eq("Ada")
    expect(merged.profile.timezone).to eq("UTC")
    expect(merged.profile).not_to be(base.profile)
    expect(merged.plan).to eq("pro")
  end

  it "recursively merges deeper nested immutable objects" do
    address_class = Class.new do
      include Immuto

      attribute :city
      attribute :country
    end

    profile_class = Class.new do
      include Immuto

      attribute :address
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    base = account_class.new(
      profile: profile_class.new(
        address: address_class.new(city: "Manila", country: "PH")
      )
    )
    incoming = account_class.new(
      profile: profile_class.new(
        address: address_class.new(city: "Cebu", country: "PH")
      )
    )

    merged = base.merge(incoming)

    expect(merged.profile.address.city).to eq("Cebu")
    expect(merged.profile.address.country).to eq("PH")
    expect(merged.profile.address).not_to be(base.profile.address)
  end

  it "replaces arrays and hashes by incoming value when merging" do
    post_class = Class.new do
      include Immuto

      attribute :tags
      attribute :meta
    end

    base = post_class.new(tags: %w[ruby], meta: { published: false })
    incoming = post_class.new(tags: %w[ruby immutable], meta: { published: true })

    merged = base.merge(incoming)

    expect(merged.tags).to eq(%w[ruby immutable])
    expect(merged.meta).to eq(published: true)
  end

  it "validates merged values" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    base = klass.new(age: 24)
    incoming = klass.allocate
    incoming.instance_variable_set(:@age, -1)
    incoming.freeze

    expect { base.merge(incoming) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "raises when merging a different object type" do
    user = user_class.new(name: "Jeff", age: 24)

    expect { user.merge(Object.new) }
      .to raise_error(Immuto::MergeError, "cannot merge #{user_class} with Object")
  end

  it "raises when merging a different immutable class" do
    other_class = Class.new do
      include Immuto

      attribute :name
      attribute :age
    end
    user = user_class.new(name: "Jeff", age: 24)
    other = other_class.new(name: "Jeff", age: 24)

    expect { user.merge(other) }
      .to raise_error(Immuto::MergeError, "cannot merge #{user_class} with #{other_class}")
  end

  it "builds immutable objects with a yielded builder" do
    user = user_class.build do |builder|
      builder.name "Jeff"
      builder.age 24
    end

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
    expect(user).to be_frozen
  end

  it "builds immutable objects with an instance-eval builder" do
    user = user_class.build do
      name "Jeff"
      age 24
    end

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
  end

  it "builds immutable objects with explicit builder setters" do
    user = user_class.build do |builder|
      builder.set(:name, "Jeff")
      builder.age = 24
    end

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
  end

  it "applies defaults when building with a builder" do
    klass = Class.new do
      include Immuto

      attribute :name
      attribute :active, default: true
    end

    user = klass.build do |builder|
      builder.name "Jeff"
    end

    expect(user.active).to be(true)
  end

  it "validates values when building with a builder" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    expect do
      klass.build do |builder|
        builder.age(-1)
      end
    end.to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "raises for missing attributes when building with a builder" do
    expect do
      user_class.build do |builder|
        builder.name "Jeff"
      end
    end.to raise_error(Immuto::MissingAttributeError, "missing attribute: :age")
  end

  it "raises for unknown attributes used in a builder" do
    expect do
      user_class.build do |builder|
        builder.email "jeff@example.com"
      end
    end.to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")
  end

  it "raises when a builder block is missing" do
    expect { user_class.build }
      .to raise_error(ArgumentError, "builder requires a block")
  end

  it "rebuilds immutable objects with a builder" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.rebuild do |builder|
      builder.age 25
    end

    expect(user.age).to eq(24)
    expect(updated.age).to eq(25)
    expect(updated.name).to eq("Jeff")
    expect(updated).to be_frozen
  end

  it "rebuilds immutable objects with an instance-eval builder" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.rebuild do
      age 25
    end

    expect(updated.age).to eq(25)
  end

  it "allows rebuild builders to read current values" do
    user = user_class.new(name: "Jeff", age: 24)
    updated = user.rebuild do |builder|
      builder.age builder.age + 1
    end

    expect(updated.age).to eq(25)
  end

  it "returns itself when rebuild has no changes" do
    user = user_class.new(name: "Jeff", age: 24)

    rebuilt = user.rebuild do |builder|
      builder.age
      nil
    end

    expect(rebuilt).to be(user)
  end

  it "validates values when rebuilding with a builder" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    user = klass.new(age: 24)

    expect do
      user.rebuild do |builder|
        builder.age(-1)
      end
    end.to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "captures snapshots of immutable objects" do
    user = user_class.new(name: "Jeff", age: 24)
    snapshot = user.snapshot

    expect(snapshot).to be_a(Immuto::Snapshot)
    expect(snapshot).to be_frozen
    expect(snapshot.object_class).to be(user_class)
    expect(snapshot.to_h).to eq(name: "Jeff", age: 24)
    expect(snapshot.to_h).to be_frozen
  end

  it "freezes and detaches snapshot data" do
    post_class = Class.new do
      include Immuto

      attribute :tags
    end

    tags = ["ruby"]
    post = post_class.new(tags:)
    snapshot = post.snapshot

    tags << "immutable"

    expect(snapshot.to_h).to eq(tags: ["ruby"])
    expect(snapshot.to_h[:tags]).to be_frozen
    expect { snapshot.to_h[:tags] << "later" }.to raise_error(FrozenError)
  end

  it "serializes nested immutable objects inside snapshots" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(profile: profile_class.new(display_name: "Jeff"))

    expect(account.snapshot.to_h).to eq(
      profile: { display_name: "Jeff" }
    )
  end

  it "restores immutable objects from snapshots" do
    user = user_class.new(name: "Jeff", age: 24)
    restored = user_class.restore(user.snapshot)

    expect(restored).to eq(user)
    expect(restored).not_to be(user)
    expect(restored).to be_frozen
  end

  it "reports changes since a snapshot" do
    user = user_class.new(name: "Jeff", age: 24)
    snapshot = user.snapshot
    updated = user.with(age: 25)

    expect(updated.changes_since(snapshot)).to eq(
      age: { from: 24, to: 25 }
    )
  end

  it "reports nested serialized changes since a snapshot" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
      attribute :timezone
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(
      profile: profile_class.new(display_name: "Jeff", timezone: "UTC")
    )
    snapshot = account.snapshot
    updated = account.with_path(:profile, :display_name, "Ada")

    expect(updated.changes_since(snapshot)).to eq(
      profile: {
        display_name: { from: "Jeff", to: "Ada" }
      }
    )
  end

  it "returns an empty change set when nothing changed since a snapshot" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.changes_since(user.snapshot)).to eq({})
  end

  it "compares snapshots by class and data" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.snapshot).to eq(user.snapshot)
    expect(user.snapshot.hash).to eq(user.snapshot.hash)
  end

  it "raises when restoring from a non-snapshot" do
    expect { user_class.restore({}) }
      .to raise_error(Immuto::SnapshotError, "expected Immuto::Snapshot")
  end

  it "raises when restoring a snapshot for another class" do
    other_class = Class.new do
      include Immuto

      attribute :name
      attribute :age
    end
    user = user_class.new(name: "Jeff", age: 24)

    expect { other_class.restore(user.snapshot) }
      .to raise_error(Immuto::SnapshotError, "snapshot belongs to #{user_class}, not #{other_class}")
  end

  it "builds immutable objects from hashes" do
    user = user_class.from_h("name" => "Jeff", "age" => 24)

    expect(user.name).to eq("Jeff")
    expect(user.age).to eq(24)
    expect(user).to be_frozen
  end

  it "applies defaults when building from hashes" do
    klass = Class.new do
      include Immuto

      attribute :name
      attribute :active, default: true
    end

    user = klass.from_h(name: "Jeff")

    expect(user.active).to be(true)
  end

  it "validates attributes during initialization" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    expect(klass.new(age: 24).age).to eq(24)

    expect { klass.new(age: -1) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "uses custom validation messages" do
    klass = Class.new do
      include Immuto

      attribute :age,
                validate: ->(value) { value >= 0 },
                message: "must be greater than or equal to 0"
    end

    expect { klass.new(age: -1) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age: must be greater than or equal to 0")
  end

  it "validates default values" do
    klass = Class.new do
      include Immuto

      attribute :score,
                default: -1,
                validate: ->(value) { value >= 0 }
    end

    expect { klass.new }
      .to raise_error(Immuto::ValidationError, "validation failed for :score")
  end

  it "validates updates made with with" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    user = klass.new(age: 24)

    expect { user.with(age: -1) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "validates updates made with with_path" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name, validate: ->(value) { !value.empty? }
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(profile: profile_class.new(display_name: "Jeff"))

    expect { account.with_path(:profile, :display_name, "") }
      .to raise_error(Immuto::ValidationError, "validation failed for :display_name")
  end

  it "validates objects built from hashes" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    expect { klass.from_h(age: -1) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "wraps validator exceptions in validation errors" do
    klass = Class.new do
      include Immuto

      attribute :age, validate: ->(value) { value >= 0 }
    end

    expect { klass.new(age: nil) }
      .to raise_error(Immuto::ValidationError, "validation failed for :age")
  end

  it "validates hashes used to build immutable objects" do
    expect { user_class.from_h(name: "Jeff") }
      .to raise_error(Immuto::MissingAttributeError, "missing attribute: :age")

    expect { user_class.from_h(name: "Jeff", age: 24, email: "jeff@example.com") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")
  end

  it "raises when from_h receives a non-hash-like value" do
    expect { user_class.from_h(nil) }
      .to raise_error(ArgumentError, "from_h requires a hash-like object")
  end

  it "raises when with_path does not receive a path and value" do
    user = user_class.new(name: "Jeff", age: 24)

    expect { user.with_path(:age) }
      .to raise_error(ArgumentError, "with_path requires at least one attribute and a value")
  end

  it "raises when a nested path reaches a non-nested value" do
    user = user_class.new(name: "Jeff", age: 24)

    expect { user.with_path(:name, :first, "Ada") }
      .to raise_error(Immuto::NestedUpdateError, "attribute :name does not support nested updates")
  end

  it "raises for unknown attributes in nested update paths" do
    profile_class = Class.new do
      include Immuto

      attribute :display_name
    end

    account_class = Class.new do
      include Immuto

      attribute :profile
    end

    account = account_class.new(profile: profile_class.new(display_name: "Jeff"))

    expect { account.with_path(:profile, :handle, "jeff") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :handle")
  end

  it "requires declared attributes without defaults" do
    expect { user_class.new(name: "Jeff") }
      .to raise_error(Immuto::MissingAttributeError, "missing attribute: :age")
  end

  it "allows explicit nil values for required attributes" do
    user = user_class.new(name: "Jeff", age: nil)

    expect(user.age).to be_nil
  end

  it "supports static default values" do
    klass = Class.new do
      include Immuto

      attribute :name
      attribute :active, default: true
    end

    user = klass.new(name: "Jeff")

    expect(user.active).to be(true)
  end

  it "supports callable default values" do
    calls = 0
    klass = Class.new do
      include Immuto

      attribute :tags, default: lambda {
        calls += 1
        []
      }
    end

    first = klass.new
    second = klass.new

    expect(calls).to eq(2)
    expect(first.tags).to eq([])
    expect(second.tags).to eq([])
    expect(first.tags).not_to be(second.tags)
  end

  it "preserves defaulted values when updating" do
    klass = Class.new do
      include Immuto

      attribute :name
      attribute :active, default: true
    end

    user = klass.new(name: "Jeff")
    updated = user.with(name: "Ada")

    expect(updated.name).to eq("Ada")
    expect(updated.active).to be(true)
  end

  it "raises for unknown attributes" do
    expect { user_class.new(name: "Jeff", email: "jeff@example.com") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")

    user = user_class.new(name: "Jeff", age: 24)

    expect { user.with(email: "jeff@example.com") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")
  end

  it "raises for unknown attribute options" do
    expect do
      Class.new do
        include Immuto

        attribute :name, type: String
      end
    end.to raise_error(ArgumentError, "unknown attribute option: :type")
  end

  it "raises when validate is not callable" do
    expect do
      Class.new do
        include Immuto

        attribute :age, validate: true
      end
    end.to raise_error(ArgumentError, "validate must respond to call")
  end

  it "ignores duplicate attribute declarations" do
    klass = Class.new do
      include Immuto

      attribute :name
      attribute :name
    end

    expect(klass.attribute_names).to eq([:name])
  end

  it "inherits attributes from parent immutable classes" do
    parent = Class.new do
      include Immuto

      attribute :id
    end

    child = Class.new(parent) do
      attribute :name
    end

    record = child.new(id: 1, name: "Jeff")

    expect(record.id).to eq(1)
    expect(record.name).to eq("Jeff")
    expect(child.attribute_names).to eq(%i[id name])
    expect(parent.attribute_names).to eq([:id])
  end

  it "compares objects by class and attribute values" do
    user = user_class.new(name: "Jeff", age: 24)
    same_user = user_class.new(name: "Jeff", age: 24)
    different_user = user_class.new(name: "Jeff", age: 25)

    expect(user).to eq(same_user)
    expect(user).to eql(same_user)
    expect(user.hash).to eq(same_user.hash)
    expect(user).not_to eq(different_user)
    expect(user).not_to eq(Object.new)
  end

  it "shows declared attributes in inspect" do
    user = user_class.new(name: "Jeff", age: 24)

    expect(user.inspect).to include('name="Jeff"')
    expect(user.inspect).to include("age=24")
  end
end
