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

  def self.included(base)
    base.include(Immutable)
  end
end
