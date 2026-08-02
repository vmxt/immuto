# frozen_string_literal: true

module Immuto
  # Computes value-level changes between immutable objects.
  module Diff
    def diff(other)
      raise DiffError.new(self, other) unless other.instance_of?(self.class)

      immuto_values.each_with_object({}) do |(name, value), changes|
        other_value = other.__send__(:immuto_values).fetch(name)
        diff = immuto_diff_value(value, other_value)

        changes[name] = diff unless diff.empty?
      end
    end

    private

    def immuto_diff_value(left, right)
      return {} if left == right
      return left.diff(right) if immuto_nested_diffable?(left, right)

      { from: left, to: right }
    end

    def immuto_nested_diffable?(left, right)
      left.is_a?(Immutable) && right.instance_of?(left.class)
    end
  end
end
