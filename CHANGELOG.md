# Change Log
All notable changes to ESS Pre-flight Validator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - 2025-07-21

### Added — SkillsSpec Skills Framework
- **4-Stage Validation Model** (Detection → Diagnosis → Remediation → Prevention)
  - `Add-ValidationResult` extended with `Stage`, `RootCause`, `Confidence`, `GatingSignal` fields
  - HTML report updated with 8-column layout (Stage, Diagnosis/Remediation, Gating columns)
  - All existing checks default to Detection stage (backward compatible)

- **Workday Connector Readiness** (3 new scripts)
  - `Test-WorkdayReportStructure.ps1` — validates RaaS report columns & calculated fields
  - `Test-WorkdayConnectionSharing.ps1` — verifies connections shared with all users
  - `Test-EntraWorkdaySSO.ps1` — Entra ID SSO validation (adaptive: automated or checklist)

- **ServiceNow Connector Readiness** (4 new scripts)
  - `Test-ServiceNowEndToEnd.ps1` — functional E2E tests (HRSD KB, HR cases, ITSM incidents)
  - `Test-ServiceNowOAuthConfig.ps1` — deep OAuth/OIDC diagnostics (triggered on E2E failure)
  - `Test-EntraServiceNowSSO.ps1` — Entra ID SSO validation for ServiceNow (adaptive)
  - `Test-ServiceNowConnectionSharing.ps1` — ServiceNow connection sharing validation

- **Topic End-to-End Testing** (1 new script)
  - `Test-ESSTopicEndToEnd.ps1` — functional Copilot topic tests (Workday & ServiceNow flows)

- **Connector Readiness Orchestrator**
  - `Test-ESSConnectorReadiness` function in ESS-Validator.psm1
  - New `ConnectorReadiness` scope in `Test-ESSDeploymentReadiness`

- **Menu Enhancements**
  - Workday sub-menu: [7] Report Structure, [8] Connection Sharing, [9] Entra SSO
  - New ServiceNow Deep Dive sub-menu with 5 options
  - Connectivity Suite: 4 new test options ([6]-[9])

- **Config Extensions**
  - `prod-tests.json`: Added `entra` section (app IDs, scopes) and `workday.raas` (report columns)

### Changed
- Every module is independently callable (different users may have different system permissions)
- Enhanced `Test-WorkdayEnvironmentVariables.ps1` with 4-stage output fields
- Workday Validation Suite orchestrator now includes report structure, connection sharing, and Entra SSO steps

## [1.7.0] - 2026-02-10

### Added
- **Session Mode** - Completely redesigned user experience
  - Modules load ONCE at startup (5-10 minutes)
  - All subsequent tests run INSTANTLY
  - No more waiting between tests
  - Single PS7 window stays open for multiple operations

- **ESS-Validator.exe** - One-click launcher for customers
  - Double-click to start
  - Automatically launches PowerShell 7 session
  - Professional loading screen with progress

- **Workday Sub-Menu** - Expanded test options
  - [A] Run All Tests - Complete validation suite
  - [1] Connection References - Check connector authentication
  - [2] Environment Variables - RaaS account configuration
  - [3] Flow Status - Workday flows enabled/disabled
  - [4] SSO Configuration - Security domain checklist (Admin)
  - [5] Basic User Test - Test Workday API with credentials
  - [6] SSO Connectivity - Test Azure AD OAuth flow (end-user)

### Changed
- Updated time estimate from "3-5 minutes" to "5-10 minutes" (more realistic)
- Suppressed PowerApps module "unapproved verbs" warnings
- Improved menu alignment across all screens
- Removed Sign In/Verify steps from main menu (handled automatically)

### Fixed
- Fixed `Test-WorkdaySSOConfiguration.ps1` script-level param causing prompts
- Fixed stray character in `Test-WorkdaySSOConnectivity.ps1`

## [1.6.0] - 2026-02-04

### Added
- **CAPE/FastTrack Getting Started Guide** - Comprehensive 7-page documentation
  - Complete guide for internal teams: CAPE, FastTrack, Engineering
  - Covers all scripts: ESS-Validator, Start-ESSValidation, Start-ESSDeployment, WorkdaySuite
  - Troubleshooting matrix, prerequisites, Entra ID permissions
  - Located at: `Documentation/CAPE-FT-Getting-Started.md`

- **CSV Export for Standalone Workday Validation**
  - New `-ExportPath` parameter for `Invoke-WorkdayValidationSuite.ps1`
  - Auto-generates timestamped CSV files
  - Clean summary banner at end of run
  - Tip shown when export path not provided

### Fixed
- **Export-ModuleMember errors** - WorkdaySuite scripts now work standalone
  - Wrapped `Export-ModuleMember` in conditional check
  - Scripts can be dot-sourced or run directly without errors
  - Affected: `Test-WorkdayEnvironmentVariables.ps1`, `Test-WorkdayConnectionReferences.ps1`, `Test-WorkdayFlowStatus.ps1`

### Changed
- Cleaned all lab/personal references from codebase
  - Environment IDs replaced with generic `00000000-0000-0000-0000-000000000000`
  - User references changed to `admin@contoso.com`
  - Ready for internal distribution

- Username prompt simplified in `Test-WorkdayWorkflows.ps1`
  - Changed from "Enter ISU Username" to "Enter Username"

### Documentation
- Updated all example environment IDs to generic placeholders
- Added Workday Validator Agent Guide (`PowerPlatform/Workday-Validator-Agent-Guide.md`)

---

## [1.5.0] - 2026-01-22

### Added
- **NEW: `Test-WorkdayWorkflows.ps1`** - Tests ALL 17 ESS pre-configured workflows
  - Calls actual Workday SOAP APIs to validate security domains
  - Tests each workflow and reports `[PASS]`/`[FAIL]`
  - **Read Workflows (15)**: Employee ID, Company Code, Cost Center, Hire Date, Employment Info, Position Number, Service Anniversary, National IDs, Passports, Visas, Language Info, Certifications, Base Compensation, Compensation Ratio, Emergency Contact
  - **Write Workflows (2)**: Update Email, Update Phone
  - `-SkipWriteTests` flag for production safety
  - Summary shows which security domains need to be granted
  - No more guessing - **proves** permissions work!

### Example Output
```
Testing Employee ID... [PASS]
Testing Company Code... [PASS]
Testing Compensation... [FAIL] Permission Denied
Testing Emergency Contact... [PASS*] (API works, no data found)
```

---

## [1.4.1] - 2026-01-22

### Changed
- **`Test-WorkdaySSOConfiguration.ps1` v2.0** - Complete UX overhaul
  - **Prompt-and-confirm approach**: Auto-detects the 4 required connections, lets you confirm or correct
  - Shows only the connections that matter (OAuthUser, ISU_WQL, ISU_Generic, Dataverse)
  - Removed noisy 19-connection dump from previous version
  - Clean `[PASS]`/`[FAIL]` status per connection
  - New CLI parameters for non-interactive use:
    - `-OAuthUserConnection` - Specify OAuthUser connection name
    - `-ISUWQLConnection` - Specify ISU_WQL connection name  
    - `-ISUGenericConnection` - Specify ISU_Generic connection name
    - `-DataverseConnection` - Specify Dataverse connection name
    - `-SkipPrompts` - Auto-accept detected connections (for automation)

### Example Usage
```powershell
# Interactive (prompts for each connection)
.\Test-WorkdaySSOConfiguration.ps1 -EnvironmentId "abc123"

# Non-interactive (provide names directly)
.\Test-WorkdaySSOConfiguration.ps1 -EnvironmentId "abc123" `
    -OAuthUserConnection "oauth user" `
    -ISUWQLConnection "isu wql entra" `
    -ISUGenericConnection "isu generic entra" `
    -SkipPrompts
```

---

## [1.4.0] - 2026-01-22

### Added
- **NEW: `Test-WorkdaySSOConfiguration.ps1`** - Deep SSO diagnostic tool for Workday integration
  - Documents all 17 ESS workflows with required Workday security domains
  - Generates printable checklist for Workday Administrator
  - Provides test patterns for users to validate permissions

- **SSO Security Domain Documentation**
  - READ workflows: Employee ID, Company Code, Cost Center, Base Compensation, Compensation Ratio, Service Anniversary, Hire Date, Employment Info, Position Number, Emergency Contact, Certifications, National IDs, Passports, Visas, Language Info
  - WRITE workflows: Update Email, Update Phone Number
  - ISU_WQL_COPILOT domains: Workday Accounts, Custom Report Creation, Person Data: Work Email, Worker Data: Current Staffing Info, Worker Data: Worker ID, Setup: Tenant Setup - Reporting
  - ISU_Generic_COPILOT domains: Integration Build, Job Information, Setup: Compensation Packages
  - PII flagging for sensitive data (National IDs, Passports, Visas, Emergency Contacts)

- **Workday Admin Checklist Generator** (`-GenerateChecklist` flag)
  - Exports complete security domain requirements to text file
  - Ready to hand off to Workday team

### Changed
- `Invoke-WorkdayValidationSuite.ps1` now supports `-IncludeSSODiagnostics` flag
- Security domains mapped from Microsoft documentation Task 6
- "Employee as self" concept explained: user's OAuth token + self-service permissions
- Connection purpose detection via name pattern matching (oauth/wql/generic/isu)

## [1.3.1] - 2026-01-21

### Added
- **Simplified Agent Selection UX** in `Start-ESSValidation.ps1`
  - Removed confusing device code authentication flow
  - Shows Copilot Studio URL hint so users can easily find their agent names
  - Clean 2-option menu: Enter agent name or Skip (full validation)
  
- **Enhanced Conditional Access Policy Output**
  - Now lists actual policy names instead of just count
  - Shows CA-enabled, MFA-required, and compliant device policies separately
  - Example: `CA Policies: PolicyName1, PolicyName2, PolicyName3`

- **Enhanced ServiceNow Flow Listing**
  - Groups flows by HRSD (HR Service Delivery) and ITSM (IT Service Management)
  - Shows categorized flow names for easier identification
  - Example: `HRSD Flows: Get HR Cases, Create HR Ticket...`

- **Enhanced SAP SuccessFactors Flow Listing**
  - Groups flows by category (User Data, Org Chart, etc.)
  - Ready to display when SAP flows exist in environment

- **Standalone WorkdaySuite Execution**
  - All WorkdaySuite tools can run standalone via dot-sourcing
  - Example: `. .\Test-WorkdayConnectionReferences.ps1; Test-WorkdayConnectionReferences -EnvironmentId "env-id"`

### Fixed
- **Flow Matching Bug** - Now correctly finds both "Workday" and "Workday Get User Context" flows
  - Cause: Previous logic skipped ESS patterns when any Workday flow was found
  - Fix: Always includes ESS-related patterns for ESS agent names
  
- **Removed Hardcoded Default Agent Name**
  - Previous: Defaulted to "Employee Self-Service Agent"
  - Fix: No default - customers rename agents, so we prompt for actual name

### Changed
- Agent selection simplified from 4 options to 2 options
- Copilot Studio URL displayed as hint: `https://copilotstudio.preview.microsoft.com/environments/{envId}/bots`
- Module version updated to 1.3.1

### Technical Details
- `Get-AgentName` function rewritten for simplicity
- Flow discovery pattern matching improved for accuracy
- CA policy listing uses `$policy.DisplayName` from Graph API response
- ServiceNow/SAP flows categorized using name pattern matching

## [1.3.0] - 2026-01-21

### Added
- **NEW: Solution-Scoped Validation Mode** - Dramatically reduces noise by validating only components relevant to your agent
  - New `-AgentName` parameter on `Test-ESSDeploymentReadiness` 
  - Example: `Test-ESSDeploymentReadiness -AgentName "Employee Self-Service Demo" -EnvironmentId $envId`
  - Auto-discovers agent's flows, connections, and env vars via pattern matching
  - Reduces check count from 467 → ~50 (for typical ESS deployment)
  
- **NEW: `Test-AgentDiscovery.ps1`** - Standalone script to test agent/solution component discovery
  - Useful for verifying what components will be validated before running full validation
  - Discovers ESS-related flows by name patterns (Workday*, ServiceNow*, SAP*, ESS*)
  - Identifies active vs orphaned connections

- **NEW: `Get-AgentSolutionComponents` function** - Exported helper for programmatic solution discovery

### Fixed
- **"Error Error Error Error" display bug** in Workday connection status
  - Cause: `$conn.Statuses` is an array, was printing all status entries
  - Fix: Now extracts `$conn.Statuses[0].Status` for primary status display
  - Affected file: `WorkdaySuite/Test-WorkdayConnectionReferences.ps1`

### Changed
- WorkdaySuite scripts now accept `-ScopedConnections` and `-ScopedFlows` parameters
- Solution-scoped mode shows "(Solution-Scoped: N connection(s))" in output
- Validation summary now indicates when running in scoped mode
- Module version updated to 1.3.0

### Technical Details
- Solution discovery uses flow name pattern matching (no Dataverse API required)
- ESS flow patterns: `Workday*`, `ServiceNow*`, `SAP*SuccessFactors*`, `*ESS*`, `*Employee Self*`
- Fallback: If agent discovery fails, validation reverts to full environment scan with warning
- Connection filtering: Solution-scoped mode only validates Connected (active) connections

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
