# frozen_string_literal: true

require "json"

module Immuto
  # Instance and class-level behavior mixed into classes that include Immuto.
  module Immutable
    include Diff
    include History
    include Merge

    VALID_ATTRIBUTE_NAME = /\A[a-z_]\w*\z/
    private_constant :VALID_ATTRIBUTE_NAME

    def self.included(base)
      base.extend(ClassMethods)
      base.extend(History::ClassMethods)
    end

    def with(**changes)
      return self if changes.empty?

      normalized_changes = normalize_immuto_attributes(changes)
      validate_known_immuto_attributes!(normalized_changes)

      self.class.new(**immuto_values, **normalized_changes)
    end

    def with_path(*path_and_value)
      raise ArgumentError, "with_path requires at least one attribute and a value" if path_and_value.length < 2

      value = path_and_value.pop
      path = path_and_value.map { |key| normalize_immuto_attribute_key(key) }

      immuto_with_path(path, value)
    end

    def to_h
      immuto_values.transform_values { |value| immuto_serializable_value(value) }
    end

    def to_json(*)
      JSON.generate(to_h, *)
    end

    def ==(other)
      other.instance_of?(self.class) && other.__send__(:immuto_values) == immuto_values
    end
    alias eql? ==

    def hash
      [self.class, immuto_values].hash
    end

    def inspect
      attributes = immuto_values.map { |name, value| "#{name}=#{value.inspect}" }.join(" ")

      "#<#{self.class} #{attributes}>"
    end

    private

    def initialize(**attributes)
      normalized_attributes = normalize_immuto_attributes(attributes)
      validate_known_immuto_attributes!(normalized_attributes)

      self.class.attributes.each do |attribute|
        value = immuto_value_for(attribute, normalized_attributes)
        attribute.validate(value)
        instance_variable_set("@#{attribute.name}", value)
      end

      freeze
    end

    def immuto_values
      self.class.attribute_names.to_h do |name|
        [name, instance_variable_get("@#{name}")]
      end
    end

    def normalize_immuto_attributes(attributes)
      attributes.each_with_object({}) do |(key, value), normalized|
        normalized[normalize_immuto_attribute_key(key)] = value
      end
    end

    def normalize_immuto_attribute_key(key)
      key.to_sym
    rescue NoMethodError
      raise UnknownAttributeError, key
    end

    def immuto_with_path(path, value)
      attribute = path.first
      validate_known_immuto_attributes!({ attribute => nil })

      return with(**{ attribute => value }) if path.one?

      nested_value = public_send(attribute)
      raise NestedUpdateError, attribute unless nested_value.respond_to?(:with_path)

      with(**{ attribute => nested_value.with_path(*path.drop(1), value) })
    end

    def immuto_serializable_value(value)
      return value.to_h if value.is_a?(Immutable)
      return value.map { |item| immuto_serializable_value(item) } if value.is_a?(Array)
      return value.transform_values { |nested_value| immuto_serializable_value(nested_value) } if value.is_a?(Hash)

      value
    end

    def immuto_value_for(attribute, attributes)
      return attributes[attribute.name] if attributes.key?(attribute.name)
      return attribute.default_value if attribute.default?

      raise MissingAttributeError, attribute.name
    end

    def validate_known_immuto_attributes!(attributes)
      unknown = attributes.keys - self.class.attribute_names
      raise UnknownAttributeError, unknown.first if unknown.any?
    end

    # DSL methods available on classes that include Immuto.
    module ClassMethods
      def attribute(name, **options)
        validate_immuto_attribute_options!(options)

        attribute = build_immuto_attribute(name, options)
        validate_immuto_attribute_name!(attribute.name)

        existing_attribute = immuto_attributes.find { |declared| declared.name == attribute.name }
        return existing_attribute if existing_attribute

        immuto_attributes << attribute
        attr_reader attribute.name

        attribute
      end

      def attributes
        immuto_attributes.dup.freeze
      end

      def from_h(attributes)
        raise ArgumentError, "from_h requires a hash-like object" unless attributes&.respond_to?(:to_h)

        attributes = attributes.to_h
        raise ArgumentError, "from_h requires a hash-like object" unless attributes.is_a?(Hash)

        new(**attributes)
      end

      def attribute_names
        immuto_attributes.map(&:name).freeze
      end

      def immuto_attributes
        @immuto_attributes ||= inherited_immuto_attributes
      end

      private

      def build_immuto_attribute(name, options)
        attribute_options = { name: }
        attribute_options[:default] = options[:default] if options.key?(:default)
        attribute_options[:validator] = options[:validate] if options.key?(:validate)
        attribute_options[:message] = options[:message] if options.key?(:message)

        Attribute.new(**attribute_options)
      end

      def inherited_immuto_attributes
        return [] unless superclass.respond_to?(:attributes)

        superclass.attributes.dup
      end

      def validate_immuto_attribute_options!(options)
        unknown = options.keys - %i[default message validate]
        return if unknown.empty?

        raise ArgumentError, "unknown attribute option: #{unknown.first.inspect}"
      end

      def validate_immuto_attribute_name!(name)
        return if VALID_ATTRIBUTE_NAME.match?(name.to_s)

        raise ArgumentError, "#{name.inspect} is not a valid immutable attribute name"
      end
    end
  end
end
