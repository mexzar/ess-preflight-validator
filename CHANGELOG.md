# Change Log
All notable changes to ESS Pre-flight Validator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-10

### Added
- User context detection in Start-ESSValidation.ps1
- Account switching capability with -AccountId parameter
- Permission checking display (Global Admin, Power Platform Admin, Copilot License)
- Profile save/load functionality for repeat validations
- Phased deployment wizard (Start-ESSDeployment.ps1) with 6 phases
- Progress save/resume for deployment workflow
- Phase-specific HTML report generation
- Comprehensive documentation suite

### Fixed
- Error handling for DLP policy checks (ENV-008)
- Error handling for Conditional Access policy checks (AUTH-002)
- Removed technical error messages in production output
- Changed inappropriate "Failed" status to "Warning" for permission issues
- Profile save PSCustomObject/hashtable conversion issue
- HTML report generation (restored static HTML, removed JavaScript issues)

### Changed
- ENV-003 message: Clarified Managed Environment is optional for ESS
- ENV-008 message: Changed from error to informational warning
- AUTH-002 message: Improved permission requirement messaging
- Status indicators: More appropriate warning vs. error classifications

### Security
- Added -ErrorAction SilentlyContinue to prevent credential leakage
- Suppressed technical API errors in production output

## [1.0.0] - 2026-01-09

### Added
- Initial release of ESS Pre-flight Validator
- 50+ validation checkpoints across all deployment phases
- HTML report generation
- Export to JSON and CSV formats
- Interactive validation wizard
- Basic error handling

### Known Issues
- JavaScript-enhanced reports had rendering issues (resolved in 1.1.0)
- Profile save had type conversion errors (resolved in 1.1.0)
- Technical errors displayed to users (resolved in 1.1.0)

---

## Version Tags

- `v1.1.0` - Production-ready stable release (2026-01-10)
- `v1.0.0` - Initial release (2026-01-09)

## Backup Strategy

Versioned backups are created before significant changes:
- Format: `ESS-PreFlight-Validator-vX.Y.Z-YYYYMMDD-HHMMSS.zip`
- Location: User Desktop
- Includes: All PowerShell scripts, modules, and documentation
