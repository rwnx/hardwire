# Changelog
This document lists the changes between release versions.

These are user-facing changes. To see the changes in the code between versions you can compare git tags.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Types of changes
  * `Added` for new features.
  * `Changed` for changes in existing functionality.
  * `Deprecated` for soon-to-be removed features.
  * `Removed` for now removed features.
  * `Fixed` for any bug fixes.
  * `Security` in case of vulnerabilities.

  -------------------------------------------------------------------
## [Unreleased]

## [0.4.2] 2020-04-05
- Changed some internal documentation to improve readability.
- Changed some internal registration logic to improve collision/duplicate detection.
- Changed some macro sequences to make them easier to understand.

## [0.4.1] 2020-02-05
 - Fixed an issue where resolving a dependency in a different namespace would fail.
 - Fixed an issue where an untagged dependency would fail to resolve in certain cases.

## [0.4.0] 2020-02-03
 - Removed Complex tags - This will be revisited at a future date. All documentation has been reverted to a single string-based system.
    In future, this may be used for multiple registrations/optional resolution. As the current feature wasn't providing this, it's been removed.
 - Added some additional compile checks for invalid tag strings.
 - Fixed some typos in compile errors.
 - Added a new macro for resolving depedencies by their tagstring, rather than the tag classes. This means that humans can use them, instead!

## [0.3.1] 2020-02-02
 - Fix a versioning metadata issue. Code is unchanged.

## [0.3.0] 2020-02-02
 - Added more compile-time checks to raise descriptive errors on register.
 - Fixed a bug where circular dependencies could be registered. Registrations now need to happen in the correct order.

## [0.2.0] 2020-01-23
 - Fixed an issue where nested `Module::Classes` could not be registered.
 - Fixed an issue where hard-to-infer blocks could not be registered

## [0.1.0] 2020-01-22
 - Package Release - Hooray!
