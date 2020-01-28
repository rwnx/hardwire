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
 - Added more compile-time checks to raise descriptive errors on register. This also fixes a bug where circular dependencies could be registered.

## [0.2.0] 2020-01-23
 - Fixed an issue where nested `Module::Classes` could not be registered.
 - Fixed an issue where hard-to-infer blocks could not be registered 

## [0.1.0] 2020-01-22
 - Package Release - Hooray!
