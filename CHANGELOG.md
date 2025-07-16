# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of DotEnv GitHub Action
- Support for pulling secrets from DotEnv platform
- Multiple output formats (env, json, yaml, shell, dockerfile)
- Export variables to GitHub environment
- Hierarchical secret management (project/target/environment)
- Variable interpolation support
- Cross-platform compatibility (Linux, macOS, Windows)
- Automatic CLI installation
- Support for custom CLI versions
- Organization override capability
- Custom API URL support for enterprise/testing

### Security
- Automatic masking of sensitive values in logs
- Secure API key handling through GitHub Secrets

## Example Version Format

<!--
## [1.0.0] - 2025-01-20

### Added
- New feature description

### Changed
- Modified behavior description

### Deprecated
- Features that will be removed

### Removed
- Features that were removed

### Fixed
- Bug fix descriptions

### Security
- Security improvements
-->