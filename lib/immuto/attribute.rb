# frozen_string_literal: true

module Immuto
  # Metadata for an immutable attribute declared on an Immuto class.
  class Attribute
    attr_reader :name

    def initialize(name:)
      @name = normalize_name(name)
      freeze
    end

    def ==(other)
      other.is_a?(self.class) && other.name == name
    end
    alias eql? ==

    def hash
      [self.class, name].hash
    end

    private

    def normalize_name(name)
      name.to_sym
    rescue NoMethodError
      raise ArgumentError, "attribute name must be a string or symbol"
    end
  end
end
