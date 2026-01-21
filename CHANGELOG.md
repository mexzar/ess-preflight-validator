# Change Log
All notable changes to ESS Pre-flight Validator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-21

### Added
- **NEW: Workday Validation Suite** (`PowerShell/WorkdaySuite/`)
  - `Invoke-WorkdayValidationSuite.ps1` - Main entry point for comprehensive Workday validation
  - `Test-WorkdayEnvironmentVariables.ps1` - Validates critical Dataverse environment variables:
    - `EmployeeContextRequestAccountName` (CRITICAL - must be manually configured)
    - `EmployeeContextRequestReportName` (default: "WD User Context")
    - `EmployeeContextRequestReportInstanceName` (default: "Report2")
  - `Test-WorkdayConnectionReferences.ps1` - Checks Power Platform connection status
  - `Test-WorkdayFlowStatus.ps1` - Validates Power Automate flow enabled/disabled state
  - Consolidated `Test-WorkdayConnectivity.ps1` and `Test-WorkdaySSOConnectivity.ps1` into suite

### Changed
- `Test-ESSExternalSystems` now automatically cascades into deep Workday validation when Workday solution is detected
- Extended checkpoint IDs for Workday: WD-ENV-001, WD-ENV-002, WD-ENV-003, WD-CONN-REF-xxx, WD-FLOW-xxx
- Module version updated to 1.2.0

### Technical Details
- Workday suite loads via dot-sourcing when Workday flows detected
- Environment variables validated against Microsoft documentation defaults
- Connection references checked for Connected/Error status
- Flow status validated for Enabled state (disabled = Failed)
- Suite provides direct links to Power Platform portal for manual verification

## [1.1.2] - 2026-01-11

### Added
- Interactive environment selection to Start-ESSDeployment.ps1 (matching Start-ESSValidation.ps1 UX)
- `Clear-ValidationResults` helper function exported from module
- Helpful TIP shown when progress exists: prompts user to reset for fresh validation
- Detailed manual review checklist for Phase 4 (ESS Agent Configuration)
- Comprehensive testing checklist for Phase 5 (Testing & UAT) with user pause
- Production readiness checklist for Phase 6 with pre-deployment verification steps

### Fixed
- **CRITICAL**: Fixed validation result accumulation bug that broke Start-ESSValidation HTML reports
- Power Platform module detection now uses `Get-AdminPowerAppEnvironment` instead of invalid `Get-PowerAppAccount`
- Workday/ServiceNow solution detection now uses correct syntax: `Get-AdminFlow -EnvironmentName | Where-Object`
- Phase 6 invalid "Quick" scope parameter replaced with valid "Publishing" scope
- Start-ESSDeployment now calls `Clear-ValidationResults` before each phase to prevent accumulation
- Individual validation functions no longer clear `$script:ValidationResults` (prevents data loss in Full scope)

### Changed
- Reset menu option now says "[R] - Reset and RE-RUN ALL PHASES from scratch" for clarity
- Phase 4 displays manual review requirements before running automated checks
- Phase 5 shows detailed testing checklist and pauses for user confirmation
- Phase 6 shows production checklist before running final automated validation
- Improved professional communication and user guidance throughout deployment wizard

### Technical Details
- Environment selection flow: saved environment check → user confirmation → Out-GridView picker
- Flow detection fixed: `Get-AdminFlow -EnvironmentName $envId | Where-Object { $_.DisplayName -like "*Workday*" }`
- Validation pattern: Test-ESSDeploymentReadiness clears at start → functions accumulate → returns combined results
- Deployment wizard pattern: Clear-ValidationResults before each phase → individual function returns isolated results

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
