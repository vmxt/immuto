# frozen_string_literal: true

module Immuto
  # Metadata for an immutable attribute declared on an Immuto class.
  class Attribute
    UNDEFINED = Object.new.freeze
    private_constant :UNDEFINED

    attr_reader :name

    def initialize(name:, default: UNDEFINED, validator: UNDEFINED, message: nil)
      @name = normalize_name(name)
      @default = default
      @validator = validator
      @message = message
      validate_validator!
      freeze
    end

    def default?
      !@default.equal?(UNDEFINED)
    end

    def default_value
      return @default.call if @default.respond_to?(:call)

      @default
    end

    def validate(value)
      return unless validator?
      return if @validator.call(value)

      raise ValidationError.new(name, @message)
    rescue ValidationError
      raise
    rescue StandardError => e
      raise ValidationError.new(name, @message), cause: e
    end

    def ==(other)
      other.is_a?(self.class) &&
        other.name == name &&
        other.instance_variable_get(:@default) == @default &&
        other.instance_variable_get(:@validator) == @validator &&
        other.instance_variable_get(:@message) == @message
    end
    alias eql? ==

    def hash
      [self.class, name, @default, @validator, @message].hash
    end

    private

    def validator?
      !@validator.equal?(UNDEFINED)
    end

    def validate_validator!
      return unless validator?
      return if @validator.respond_to?(:call)

      raise ArgumentError, "validate must respond to call"
    end

    def normalize_name(name)
      name.to_sym
    rescue NoMethodError
      raise ArgumentError, "attribute name must be a string or symbol"
    end
  end
end
