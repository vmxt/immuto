# frozen_string_literal: true

module Immuto
  # Combines immutable objects, preferring incoming values.
  module Merge
    def merge(other)
      raise MergeError.new(self, other) unless other.instance_of?(self.class)

      other_values = other.__send__(:immuto_values)
      merged_values = immuto_values.to_h do |name, value|
        [name, immuto_merge_value(value, other_values.fetch(name))]
      end

      self.class.new(**merged_values)
    end

    private

    def immuto_merge_value(left, right)
      return left.merge(right) if immuto_nested_mergeable?(left, right)

      right
    end

    def immuto_nested_mergeable?(left, right)
      left.is_a?(Immutable) && right.instance_of?(left.class)
    end
  end
end
