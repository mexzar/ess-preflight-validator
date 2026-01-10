# Change Log
All notable changes to ESS Pre-flight Validator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-01-10

### Fixed
- **CRITICAL**: Validation functions now return results properly to calling scripts
- Added `return $script:ValidationResults` to all Test-ESS* validation functions
- Each validation function now clears `$script:ValidationResults` at start to prevent result accumulation
- Fixed Start-ESSDeployment.ps1 Phase 1 showing "0 passed, 0 failed, 0 warnings" when validation checks actually ran
- Deployment wizard now correctly captures and displays validation checkpoint results
- Phase HTML reports now show accurate validation statistics

### Technical Details
- Modified functions: Test-ESSPrerequisites, Test-ESSEnvironment, Test-ESSAuthentication, Test-ESSExternalSystems, Test-ESSContent, Test-ESSTopics, Test-ESSConfiguration, Test-ESSPublishing
- Each function now follows pattern: clear results → run validations → return results
- Fixes issue where module-scoped variables weren't accessible to calling scripts

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
