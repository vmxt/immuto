# frozen_string_literal: true

module Immuto
  # Metadata for an immutable attribute declared on an Immuto class.
  class Attribute
    UNDEFINED = Object.new.freeze
    private_constant :UNDEFINED

    attr_reader :name

    def initialize(name:, default: UNDEFINED, validator: UNDEFINED, message: nil, **casting)
      @name = normalize_name(name)
      @default = default

      @type = casting.fetch(:type, UNDEFINED)
      @coercer = casting.fetch(:coerce, UNDEFINED)
      @validator = validator
      @message = message
      validate_configuration!(casting)
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
      return if @validator.equal?(UNDEFINED)
      return if @validator.call(value)

      raise ValidationError.new(name, @message)
    rescue ValidationError
      raise
    rescue StandardError => e
      raise ValidationError.new(name, @message), cause: e
    end

    def cast(value)
      value = coerce(value)
      validate_type(value)
      validate(value)
      value
    end

    def ==(other)
      other.is_a?(self.class) &&
        other.name == name &&
        other.instance_variable_get(:@default) == @default &&
        other.instance_variable_get(:@type) == @type &&
        other.instance_variable_get(:@coercer) == @coercer &&
        other.instance_variable_get(:@validator) == @validator &&
        other.instance_variable_get(:@message) == @message
    end
    alias eql? ==

    def hash
      [self.class, name, @default, @type, @coercer, @validator, @message].hash
    end

    private

    def coerce(value)
      return value if @coercer.equal?(UNDEFINED)

      @coercer.call(value)
    rescue StandardError => e
      raise ValidationError.new(name, @message), cause: e
    end

    def validate_type(value)
      return if @type.equal?(UNDEFINED)
      return if value.is_a?(@type)

      message = @message || "must be an instance of #{@type}"
      raise ValidationError.new(name, message)
    end

    def validate_type!
      return if @type.equal?(UNDEFINED)
      return if @type.is_a?(Module)

      raise ArgumentError, "type must be a class or module"
    end

    def validate_casting_options!(casting)
      unknown = casting.keys - %i[type coerce]
      return if unknown.empty?

      raise ArgumentError, "unknown attribute option: #{unknown.first.inspect}"
    end

    def validate_configuration!(casting)
      validate_casting_options!(casting)
      validate_type!
      validate_coercer!
      validate_validator!
    end

    def validate_coercer!
      return if @coercer.equal?(UNDEFINED)
      return if @coercer.respond_to?(:call)

      raise ArgumentError, "coerce must respond to call"
    end

    def validate_validator!
      return if @validator.equal?(UNDEFINED)
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
