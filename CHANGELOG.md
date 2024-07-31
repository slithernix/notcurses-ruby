# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Up next I need to look into the constant pointer churn from the
typemaps. This may just be an expected thing but for instance, calling
stdplane_const gets a new memory address every call. I was under the
impression this should return a constant address. Need to look into it
more.

I'd also love to figure out how to build a type-checking mechanism
between SWIG and Ruby because it's really easy to coredump right now.

## [0.0.2] - 2024-07-31

Still a WIP with a long way to go, but at the point I can replicate
notcurses-demo in Ruby to test the extension.

### Added
- Added SWIG mixins to make SWIG-generated class instantiation cleaner,
as well as a mixin to get a hash from a SWIG-generated class instance.

### Changed
- All functions now return a hash; the :return key has the retval from
the function, while the other keys contain the mutated arguments keyed
by their parameter name.

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- Many bugfixes related to typing

### Security
- N/A

## [0.0.1] - YYYY-MM-DD

### Added
- Initial release. Crude, sorta works.

[Unreleased]: https://github.com/slithernix/notcurses-ruby/compare/v0.0.2...HEAD
[0.0.2]: https://github.com/slithernix/notcurses-ruby/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/slithernix/notcurses-ruby/releases/tag/v0.0.1
