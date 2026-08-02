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
