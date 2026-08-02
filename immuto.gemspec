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
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Uncomment the line below to require MFA for gem pushes.
  # This helps protect your gem from supply chain attacks by ensuring
  # no one can publish a new version without multi-factor authentication.
  # See: https://guides.rubygems.org/mfa-requirement-opt-in/
  # spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["CHANGELOG.md", "CODE_OF_CONDUCT.md", "LICENSE*", "README.md", "lib/**/*.rb", "sig/**/*.rbs"]
  spec.require_paths = ["lib"]
end
