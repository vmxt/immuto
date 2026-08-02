# frozen_string_literal: true

module Immuto
  # Instance and class-level behavior mixed into classes that include Immuto.
  module Immutable
    VALID_ATTRIBUTE_NAME = /\A[a-z_]\w*\z/
    private_constant :VALID_ATTRIBUTE_NAME

    def self.included(base)
      base.extend(ClassMethods)
    end

    def with(**changes)
      return self if changes.empty?

      normalized_changes = normalize_immuto_attributes(changes)
      validate_known_immuto_attributes!(normalized_changes)

      self.class.new(**immuto_values, **normalized_changes)
    end

    def ==(other)
      other.instance_of?(self.class) && other.__send__(:immuto_values) == immuto_values
    end
    alias eql? ==

    def hash
      [self.class, immuto_values].hash
    end

    private

    def initialize(**attributes)
      normalized_attributes = normalize_immuto_attributes(attributes)
      validate_known_immuto_attributes!(normalized_attributes)

      self.class.attribute_names.each do |name|
        instance_variable_set("@#{name}", normalized_attributes[name])
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

    def validate_known_immuto_attributes!(attributes)
      unknown = attributes.keys - self.class.attribute_names
      raise UnknownAttributeError, unknown.first if unknown.any?
    end

    # DSL methods available on classes that include Immuto.
    module ClassMethods
      def attribute(name)
        attribute = Attribute.new(name:)
        validate_immuto_attribute_name!(attribute.name)

        return attribute if attribute_names.include?(attribute.name)

        immuto_attributes << attribute
        attr_reader attribute.name

        attribute
      end

      def attributes
        immuto_attributes.dup.freeze
      end

      def attribute_names
        immuto_attributes.map(&:name).freeze
      end

      def immuto_attributes
        @immuto_attributes ||= inherited_immuto_attributes
      end

      private

      def inherited_immuto_attributes
        return [] unless superclass.respond_to?(:attributes)

        superclass.attributes.dup
      end

      def validate_immuto_attribute_name!(name)
        return if VALID_ATTRIBUTE_NAME.match?(name.to_s)

        raise ArgumentError, "#{name.inspect} is not a valid immutable attribute name"
      end
    end
  end
end
