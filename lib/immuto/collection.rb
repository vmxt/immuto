# frozen_string_literal: true

# Public namespace for collection helper methods.
module Immuto
  # Helpers for creating frozen collection copies.
  module Collection
    module_function

    def array(*items)
      deep_freeze(items)
    end

    def hash(values = nil, **keywords)
      data = hash_data(values, keywords)

      deep_freeze(data)
    end

    def deep_freeze(value)
      return deep_freeze_array(value) if value.is_a?(Array)
      return deep_freeze_hash(value) if value.is_a?(Hash)
      return value if immutable_object?(value) || value.frozen?

      value.dup.freeze
    rescue NoMethodError, TypeError
      value
    end

    def hash_data(values, keywords)
      return keywords if values.nil?
      raise ArgumentError, "hash requires a hash-like object" unless values.respond_to?(:to_h)

      data = values.to_h
      raise ArgumentError, "hash requires a hash-like object" unless data.is_a?(Hash)

      data.merge(keywords)
    end
    private_class_method :hash_data

    def deep_freeze_array(value)
      value.map { |item| deep_freeze(item) }.freeze
    end
    private_class_method :deep_freeze_array

    def deep_freeze_hash(value)
      value.each_with_object({}) do |(key, nested_value), copy|
        copy[deep_freeze(key)] = deep_freeze(nested_value)
      end.freeze
    end
    private_class_method :deep_freeze_hash

    def immutable_object?(value)
      defined?(Immutable) && value.is_a?(Immutable)
    end
    private_class_method :immutable_object?
  end

  def self.array(*items)
    Collection.array(*items)
  end

  def self.hash(values = nil, **keywords)
    Collection.hash(values, **keywords)
  end

  def self.deep_freeze(value)
    Collection.deep_freeze(value)
  end
end
