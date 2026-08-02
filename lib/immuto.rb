# frozen_string_literal: true

require_relative "immuto/attribute"
require_relative "immuto/immutable"
require_relative "immuto/version"

# Public namespace and include hook for immutable value objects.
module Immuto
  # Base error for Immuto-specific failures.
  class Error < StandardError; end

  # Raised when initialization or updates contain undeclared attributes.
  class UnknownAttributeError < Error
    def initialize(attribute)
      super("unknown attribute: #{attribute.inspect}")
    end
  end

  # Raised when a declared attribute is missing and has no default.
  class MissingAttributeError < Error
    def initialize(attribute)
      super("missing attribute: #{attribute.inspect}")
    end
  end

  # Raised when a nested update reaches a value that cannot be updated further.
  class NestedUpdateError < Error
    def initialize(attribute)
      super("attribute #{attribute.inspect} does not support nested updates")
    end
  end

  # Raised when an attribute value does not pass its declared validation.
  class ValidationError < Error
    def initialize(attribute, message = nil)
      detail = message ? ": #{message}" : ""

      super("validation failed for #{attribute.inspect}#{detail}")
    end
  end

  # Raised when two objects cannot be diffed together.
  class DiffError < Error
    def initialize(left, right)
      super("cannot diff #{left.class} with #{right.class}")
    end
  end

  def self.included(base)
    base.include(Immutable)
  end
end
