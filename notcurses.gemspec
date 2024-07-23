# frozen_string_literal: true

require_relative "lib/notcurses/version"
require 'pry'
Gem::Specification.new do |spec|
  spec.name = "notcurses"
  spec.version = Notcurses::VERSION
  spec.authors = ["Snake Blitzken"]
  spec.email = ["git@slithernix.com"]

  spec.summary = "Notcurses Ruby Extension Auto-Generated by SWIG"
  spec.description = "Notcurses is a modern reimagining of the classic TUI library curses. It supports true color, has stock widgets, and should be familiar enough to anyone familiar with curses, though it is not an API-compatible drop-in."
  spec.homepage = "https://github.com/slithernix/notcurses-ruby"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/slithernix/notcurses-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/slithernix/notcurses-ruby/tree/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end

  binding.pry
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.extensions = ["ext/notcurses/extconf.rb"]
  spec.require_paths = ["lib"]
end

