# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README.md with usage examples and documentation
- MIT License
- Contributing guidelines (CONTRIBUTING.md)
- .gitignore file for PowerShell, Python, and common artifacts
- Proper folder structure (scripts/powershell, examples, docs)

### Changed
- Reorganized repository structure for better maintainability
- Renamed `list_mpe` to `Get-FabricManagedPrivateEndpoints.ps1`
- Enhanced PowerShell script with:
  - Proper comment-based help
  - Parameter validation
  - Error handling with try/catch
  - Verbose output support
  - Multiple output format options (Table/List)
  - Pipeline-friendly output

### Removed
- Azure Static Web Apps workflow (not applicable to this project)
- Empty `spark` file
- Old `fabric/` directory structure

## [1.0.0] - 2025 (Initial Release)

### Added
- Initial version with basic managed private endpoint listing script
- Basic README

---

## Legend

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
