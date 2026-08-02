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
