# frozen_string_literal: true

module Immuto
  # Snapshot and restoration behavior for immutable objects.
  module History
    def snapshot
      Snapshot.new(object_class: self.class, data: to_h)
    end

    def changes_since(snapshot)
      self.class.__send__(:validate_immuto_snapshot!, snapshot)

      immuto_snapshot_diff(snapshot.to_h, to_h)
    end

    private

    def immuto_snapshot_diff(left, right)
      return {} if left == right
      return immuto_snapshot_hash_diff(left, right) if left.is_a?(Hash) && right.is_a?(Hash)

      { from: left, to: right }
    end

    def immuto_snapshot_hash_diff(left, right)
      (left.keys | right.keys).each_with_object({}) do |key, changes|
        diff = immuto_snapshot_diff(left[key], right[key])

        changes[key] = diff unless diff.empty?
      end
    end

    # Class-level snapshot restoration behavior.
    module ClassMethods
      def restore(snapshot)
        validate_immuto_snapshot!(snapshot)

        from_h(snapshot.to_h)
      end

      private

      def validate_immuto_snapshot!(snapshot)
        raise SnapshotError, "expected Immuto::Snapshot" unless snapshot.is_a?(Snapshot)
        return if snapshot.object_class.equal?(self)

        raise SnapshotError, "snapshot belongs to #{snapshot.object_class}, not #{self}"
      end
    end
  end
end
