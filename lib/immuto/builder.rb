# frozen_string_literal: true

module Immuto
  # Mutable assignment surface used to build immutable objects.
  class Builder
    attr_reader :object_class

    def initialize(object_class:, values: {})
      @object_class = object_class
      @values = normalize_values(values)
      @changes = {}
    end

    def apply(&block)
      raise ArgumentError, "builder requires a block" unless block

      block.arity.zero? ? instance_eval(&block) : block.call(self)

      self
    end

    def values
      @values.dup.freeze
    end

    def changes
      @changes.dup.freeze
    end

    def set(name, value)
      attribute = normalize_attribute_name(name)
      validate_attribute_name!(attribute)

      @values[attribute] = value
      @changes[attribute] = value
    end

    def method_missing(name, *args, &block)
      raise ArgumentError, "builder attributes do not accept blocks" if block
      raise ArgumentError, "builder attributes accept zero or one value" if args.length > 1

      attribute = normalize_builder_method_name(name)
      validate_attribute_name!(attribute)

      return @values[attribute] if args.empty?

      set(attribute, args.first)
    end

    def respond_to_missing?(name, _include_private = false)
      object_class.attribute_names.include?(normalize_builder_method_name(name)) || super
    end

    private

    def normalize_values(values)
      values.each_with_object({}) do |(name, value), normalized|
        attribute = normalize_attribute_name(name)
        validate_attribute_name!(attribute)

        normalized[attribute] = value
      end
    end

    def normalize_builder_method_name(name)
      normalize_attribute_name(name.to_s.delete_suffix("="))
    end

    def normalize_attribute_name(name)
      name.to_sym
    rescue NoMethodError
      raise UnknownAttributeError, name
    end

    def validate_attribute_name!(name)
      return if object_class.attribute_names.include?(name)

      raise UnknownAttributeError, name
    end
  end

  # Class and instance methods for building immutable objects with a block DSL.
  module BuilderDSL
    def rebuild(&)
      builder = Builder.new(object_class: self.class, values: immuto_values).apply(&)

      with(**builder.changes)
    end

    # Class-level builder construction behavior.
    module ClassMethods
      def build(&)
        builder = Builder.new(object_class: self).apply(&)

        new(**builder.values)
      end
    end
  end
end
