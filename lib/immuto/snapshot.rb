# frozen_string_literal: true

module Immuto
  # Frozen serialized state captured from an immutable object.
  class Snapshot
    attr_reader :object_class, :data

    def initialize(object_class:, data:)
      @object_class = object_class
      @data = snapshot_value(data)
      freeze
    end

    def to_h
      data
    end

    def ==(other)
      other.is_a?(self.class) && other.object_class == object_class && other.data == data
    end
    alias eql? ==

    def hash
      [self.class, object_class, data].hash
    end

    private

    def snapshot_value(value)
      return snapshot_hash(value) if value.is_a?(Hash)
      return value.map { |item| snapshot_value(item) }.freeze if value.is_a?(Array)

      snapshot_scalar(value)
    end

    def snapshot_hash(value)
      value.each_with_object({}) do |(key, nested_value), snapshot|
        snapshot[snapshot_value(key)] = snapshot_value(nested_value)
      end.freeze
    end

    def snapshot_scalar(value)
      value.dup.freeze
    rescue NoMethodError, TypeError
      value
    end
  end
end
