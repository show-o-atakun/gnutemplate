# frozen_string_literal: true

require_relative "lib/gnutemplate/version"

Gem::Specification.new do |spec|
  spec.name = "gnutemplate"
  spec.version = Gnutemplate::VERSION
  spec.authors = ["showata"]
  spec.email = ["shun_yamaguchi_tc@live.jp"]

  spec.summary = "Templates of numo-gnuplot"
  spec.description = "Templates of boxplot, histgram, etc."
  spec.homepage = "https://github.com/show-o-atakun/gnutemplate"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  # spec.metadata["allowed_push_host"] = "https://github.com/show-o-atakun/gnutemplate"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/show-o-atakun/gnutemplate"
  # spec.metadata["changelog_uri"] = "https://github.com/show-o-atakun/gnutemplate"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "numo-gnuplot"
  
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
