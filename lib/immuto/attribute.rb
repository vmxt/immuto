# frozen_string_literal: true

module Immuto
  # Metadata for an immutable attribute declared on an Immuto class.
  class Attribute
    UNDEFINED = Object.new.freeze
    private_constant :UNDEFINED

    attr_reader :name

    def initialize(name:, default: UNDEFINED)
      @name = normalize_name(name)
      @default = default
      freeze
    end

    def default?
      !@default.equal?(UNDEFINED)
    end

    def default_value
      return @default.call if @default.respond_to?(:call)

      @default
    end

    def ==(other)
      other.is_a?(self.class) && other.name == name && other.instance_variable_get(:@default) == @default
    end
    alias eql? ==

    def hash
      [self.class, name, @default].hash
    end

    private

    def normalize_name(name)
      name.to_sym
    rescue NoMethodError
      raise ArgumentError, "attribute name must be a string or symbol"
    end
  end
end
