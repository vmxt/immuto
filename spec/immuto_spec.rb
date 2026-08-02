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

  it "raises for unknown attributes" do
    expect { user_class.new(name: "Jeff", email: "jeff@example.com") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")

    user = user_class.new(name: "Jeff", age: 24)

    expect { user.with(email: "jeff@example.com") }
      .to raise_error(Immuto::UnknownAttributeError, "unknown attribute: :email")
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
end
