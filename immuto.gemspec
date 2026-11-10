# frozen_string_literal: true

require_relative "lib/immuto/version"

Gem::Specification.new do |spec|
  spec.name = "immuto"
  spec.version = Immuto::VERSION
  spec.authors = ["Jefferson"]
  spec.email = ["adrianolape@protonmail.com"]

  spec.summary = "Framework-agnostic immutable object toolkit for Ruby."
  spec.description = "Immuto provides a small include-based API for immutable Ruby value objects."
  spec.license = "MIT"
  spec.homepage = "https://github.com/vmxt/immuto"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  spec.files = Dir["CHANGELOG.md", "CODE_OF_CONDUCT.md", "LICENSE*", "README.md", "lib/**/*.rb", "sig/**/*.rbs"]
  spec.require_paths = ["lib"]
end
